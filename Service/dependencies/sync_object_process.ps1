#Requires -PSEdition Core -Version 7.2 -Modules @{ ModuleName="dbatools"; ModuleVersion="2.1.7" }

[CmdletBinding()]
param (
    [Parameter(Mandatory, Position=0)][pscustomobject]$SyncObject,
    [Parameter(Mandatory, Position=1)][Microsoft.SqlServer.Management.Smo.Server]$SourceSqlConnection,
    [Parameter(Mandatory, Position=2)][Microsoft.SqlServer.Management.Smo.Server]$TargetSqlConnection,
    [Parameter(Mandatory, Position=3)][System.Collections.Hashtable]$Config
)

$VerboseLog = $Config.VerboseLog

$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues= @{
    'Write-DbaDbTableData:EnableException' = $true
    'Invoke-DbaQuery:QueryTimeout' = 30
    'Invoke-DbaQuery:EnableException' = $true
    'Invoke-DbaQuery:MessagesToOutput' = $true
}

$current_path = Get-Item ([string]::IsNullOrWhiteSpace($PSScriptRoot) ? $PWD.Path : $PSScriptRoot)
$current_path = $current_path.Parent

#################################################
# Helper functions
#################################################

function ConvertFrom-DBNull {
    param ([Parameter(Position=0, ValueFromPipeline=$true)][object]$value)
    process { $value -is [DBNull] ? $null : $value }
}

function Get-CleanSqlIdentifiers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position=0)][pscustomobject]$SyncObject,
        [Parameter(Mandatory, Position=1)][Microsoft.SqlServer.Management.Smo.Server]$SqlConnection
    )

    $query = @'
        SELECT SyncObjectNameClean = NULLIF(CONCAT_WS('.', QUOTENAME(PARSENAME(@SyncObjectName, 3)), QUOTENAME(PARSENAME(@SyncObjectName, 2)), QUOTENAME(PARSENAME(@SyncObjectName, 1))), '')
            ,  ImportTableClean    = NULLIF(CONCAT_WS('.', QUOTENAME(PARSENAME(@ImportTable   , 3)), QUOTENAME(PARSENAME(@ImportTable   , 2)), QUOTENAME(PARSENAME(@ImportTable   , 1))), '')
            ,  ImportProcClean     = NULLIF(CONCAT_WS('.', QUOTENAME(PARSENAME(@ImportProc    , 3)), QUOTENAME(PARSENAME(@ImportProc    , 2)), QUOTENAME(PARSENAME(@ImportProc    , 1))), '')
'@

    Invoke-DbaQuery $SqlConnection -Query $query -As PSObject -SqlParameter @{
            SyncObjectName = $SyncObject.SyncObjectName
            ImportTable    = $SyncObject.ImportTable
            ImportProc     = $SyncObject.ImportProc
        }
}

function Get-TVPTypeFromProcName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position=0)][string]$ProcName,
        [Parameter(Mandatory, Position=1)][Microsoft.SqlServer.Management.Smo.Server]$SqlConnection
    )

    $query = @'
        SELECT CONCAT(QUOTENAME(SCHEMA_NAME(tt.[schema_id])), '.', QUOTENAME(tt.[name]))
        FROM sys.parameters pa
            JOIN sys.table_types tt ON tt.user_type_id = pa.user_type_id
        WHERE pa.[object_id] = OBJECT_ID(@ProcName, 'P') AND pa.[name] = '@Dataset'
'@

    Invoke-DbaQuery $SqlConnection -Query $query -As SingleValue -SqlParameter @{
            ProcName = $ProcName
        }
}

#################################################

$sw_syncItem = [Diagnostics.Stopwatch]::StartNew()
if ($VerboseLog) { Write-Output 'Start: Sync' }

try {
    $sw = [Diagnostics.Stopwatch]::StartNew()

    # Get the new and old checksums
    [Nullable[int]]$oldchecksum = $null
    [Nullable[int]]$newchecksum = $null
    if ($SyncObject.ChecksumQueryText) {
        if ($VerboseLog) { Write-Output 'Start: Checksum' } $sw.Restart()
        $oldchecksum = $SyncObject.LastSyncChecksum | ConvertFrom-DBNull
        $checksumQuery = "SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; {0}" -f $SyncObject.ChecksumQueryText
        $newchecksum = Invoke-DbaQuery $SourceSqlConnection -Query $checksumQuery -As SingleValue `
                                       -SqlParameter @{ LastSyncTime = $SyncObject.LastSyncTime } | ConvertFrom-DBNull
        if ($VerboseLog) { Write-Output "Old checksum: ${oldchecksum}" }
        if ($VerboseLog) { Write-Output "New checksum: ${newchecksum}" }
        if ($VerboseLog) { Write-Output "Done: Checksum [$($sw.Elapsed)]" }
    }

    <# If the checksums are different (and the new checksum is not zero unless SyncOnZeroChecksum is true)
        or) if the old checksum is null (meaning it has never been run, or run always)
        or) there is no ChecksumQueryText (meaning disable checksum usage)
        then run
    #>
    if ((($oldchecksum -ne $newchecksum) -and (($newchecksum -ne 0) -or $SyncObject.SyncOnZeroChecksum)) -or ($null -eq $oldchecksum) -or ($null -eq $SyncObject.ChecksumQueryText)) {
        # Get cleansed identifiers
        $Clean = Get-CleanSqlIdentifiers -SyncObject $SyncObject -SqlConnection $TargetSqlConnection
        $ImportProcClean  = $Clean.ImportProcClean
        $ImportTableClean = $Clean.ImportTableClean

        # Use the export query path override otherwise use the default - select *
        $exportQuery = if ($SyncObject.ExportQueryPath) {
            Get-Content -LiteralPath (Join-Path $current_path 'dependencies\SQL' $SyncObject.ExportQueryPath) -Raw
        } else {
            'SELECT _CollectionDate = SYSUTCDATETIME(), * FROM {0};' -f $Clean.SyncObjectNameClean
        }
        $exportQuery = "SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; {0}" -f $exportQuery

        # Set sync type (simple/complex)
        $syncType = switch ($true) {
            {($ImportProcClean) -and ($null -eq $ImportTableClean)} { 'Complex' }
            {($null -eq $ImportProcClean) -and ($ImportTableClean)} { 'Simple' }
            Default { throw "[$($SyncObject.SyncObjectName)] Invalid configuration" }
        }

        <#  DataTable vs DataSet...

            For Table Valued Parameters:
            .NET documentation recommends using a DataTable - in fact, if you try using a DataSet to fill a TVP with dbatools, it will fail

            For Write-DbaDbTableData:
            dbatools documentation recommends using a DataSet
            > Use DataSet for optimal performance as all records import in a single SqlBulkCopy call.
            > DataTable also performs well but avoid piping directly as it converts to slower DataRow processing.
        #>
        if ($VerboseLog) { Write-Output 'Start: Export' } $sw.Restart()
        # using DataSet here because it's easy to pull the DataTable out of it
        $data_src = Invoke-DbaQuery $SourceSqlConnection -Query $exportQuery -As DataSet
        if ($VerboseLog) { Write-Output "Done: Export [$($sw.Elapsed)]" }

        switch ($syncType) {
            'Complex' {
                if ($data_src.Tables[0].Rows.Count -gt 0) {
                    $ImportTypeClean = Get-TVPTypeFromProcName $ImportProcClean $TargetSqlConnection
                    # Create empty datatable in the shape of the target table type, merge the source data into it, then prep the TVP
                    $data_dst = Invoke-DbaQuery $TargetSqlConnection -Query ('DECLARE @x {0}; SELECT * FROM @x;' -f $ImportTypeClean) -As DataSet
                    # If the table type contains a magic __ID column, set it to auto-increment. This way we don't have to handle it in every export query
                    # Export queries should not have an __ID column, when the merge occurs, it will fill in row numbers automatically
                    if ($data_dst.Tables[0].Columns['__ID']) {
                        $data_dst.Tables[0].Columns['__ID'].AutoIncrement = $true
                        $data_dst.Tables[0].Columns['__ID'].AutoIncrementSeed = 1
                    }
                    $data_dst.Tables[0].Merge($data_src.Tables[0], $false, [System.Data.MissingSchemaAction]::Ignore)

                    # Prep proc parameters
                    $sqlParamImportID = switch ($SyncObject.SyncObjectLevelID) {
                        1 { New-DbaSqlParameter -ParameterName 'InstanceID' -SqlDbType Int -Value $SyncObject._InstanceID }
                        2 { New-DbaSqlParameter -ParameterName 'DatabaseID' -SqlDbType Int -Value ($SyncObject._DatabaseID ?? [DBNull]::Value) }
                        Default { throw "[$($SyncObject.SyncObjectName)] Invalid SyncObjectLevelID" }
                    }

                    # No delete step because the import proc will handle it - deletes, updates, etc
                    if ($VerboseLog) { Write-Output 'Start: Write' } $sw.Restart()
                    Invoke-DbaQuery $TargetSqlConnection -CommandType StoredProcedure -Query $ImportProcClean -QueryTimeout 180 `
                                    -SqlParameter @(
                                        $sqlParamImportID
                                        , (New-DbaSqlParameter -ParameterName 'Dataset' -SqlDbType Structured -Value $data_dst.Tables[0] -TypeName $ImportTypeClean)
                                        , (New-DbaSqlParameter -ParameterName 'Verbose' -SqlDbType Bit -Value $VerboseLog)
                                    )
                    if ($VerboseLog) { Write-Output "Done: Write [$($sw.Elapsed)]" }
                } else {
                    if ($VerboseLog) { Write-Output 'Skip: Write - No data to import' }
                }
            }
            'Simple' {
                # There's no way to know whether the export having zero records is intentional or not
                # For example, it could be a list of database errors...if their are none, then running the delete is correct
                if ($VerboseLog) { Write-Output 'Start: Delete' } $sw.Restart()
                $null = Invoke-DbaQuery $TargetSqlConnection -Query 'import.usp_SyncObject_SimpleDelete' -CommandType StoredProcedure -QueryTimeout 180 `
                                        -SqlParameter @{
                                            SyncObjectID = $SyncObject.SyncObjectID
                                            InstanceID   = $SyncObject._InstanceID
                                            DatabaseID   = $SyncObject._DatabaseID
                                            Verbose      = $VerboseLog
                                        }
                if ($VerboseLog) { Write-Output "Done: Delete [$($sw.Elapsed)]" }

                if ($data_src.Tables[0].Rows.Count -gt 0) {
                    if ($VerboseLog) { Write-Output 'Start: Write' } $sw.Restart()

                    <# Create empty datatable in the shape of the target table, add instance/database id column, then merge the source data into it.
                       It's safe to add both columns because we're using merge with the Ignore missing schema action. If the destination datatable
                       doesn't have one of these columns, it will simply be ignored and not populated/added. #>
                    $data_dst = Invoke-DbaQuery $TargetSqlConnection -Query ('SELECT TOP(0) * FROM {0};' -f $ImportTableClean) -As DataSet
                    $data_src.Tables[0].Columns.Add([System.Data.DataColumn]::new('_InstanceID', [Int], $SyncObject._InstanceID))
                    $data_src.Tables[0].Columns.Add([System.Data.DataColumn]::new('_DatabaseID', [Int], $SyncObject._DatabaseID))
                    $data_dst.Tables[0].Merge($data_src.Tables[0], $false, [System.Data.MissingSchemaAction]::Ignore)

                    Write-DbaDbTableData -InputObject $data_dst -SqlInstance $TargetSqlConnection -Table $ImportTableClean -BulkCopyTimeOut 180

                    if ($VerboseLog) { Write-Output "Done: Write [$($sw.Elapsed)]" }
                } else {
                    if ($VerboseLog) { Write-Output 'Skip: Write - No data to import' }
                }
            }
        }
    } else {
        if ($VerboseLog) { Write-Output 'Skipping sync: Checksums match' }
    }
} catch {
    $errorMsg = Get-Error $_ | Out-String
    Write-Output "Error: ${errorMsg}"
} finally {
    if ($VerboseLog) { Write-Output 'Checking in SyncObjectStatus' }
    if ($oldchecksum -ne $newchecksum) { if ($VerboseLog) { Write-Output "Set new checksum: ${newchecksum}" } }
    Invoke-DbaQuery $TargetSqlConnection -CommandType StoredProcedure -Query 'import.usp_SetSyncStatus' `
                    -SqlParameter @{
                        InstanceID   = $SyncObject._InstanceID
                        DatabaseID   = $SyncObject._DatabaseID
                        SyncObjectID = $SyncObject.SyncObjectID
                        Checksum     = $newchecksum
                        ErrorMessage = $errorMsg
                        Verbose      = $VerboseLog
                    } | Write-Output
}
Write-Output "Done: Sync [$($sw_syncItem.Elapsed)]"