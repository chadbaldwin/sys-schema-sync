#Requires -PSEdition Core -Version 7.2 -Modules @{ ModuleName="dbatools"; ModuleVersion="2.1.7" }

[CmdletBinding()]
param (
    [Parameter(Mandatory, Position=0)][pscustomobject]$SyncObject,
    [Parameter(Mandatory, Position=1)][Microsoft.SqlServer.Management.Smo.Server]$SourceSqlConnection,
    [Parameter(Mandatory, Position=2)][Microsoft.SqlServer.Management.Smo.Server]$TargetSqlConnection
)

$VerboseLog = $VerbosePreference -eq 'Continue'

$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues= @{
    'Write-DbaDbTableData:EnableException' = $true
    'Invoke-DbaQuery:EnableException' = $true
    'Invoke-DbaQuery:QueryTimeout' = 30
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

#################################################

# Write-Output ($SyncObject | ConvertTo-Json)

$sw_syncItem = [Diagnostics.Stopwatch]::StartNew()
Write-Output 'Start: Sync'
#Write-Output "SyncItem:`r`n$($SyncObject | ConvertTo-Json)"

try {
    $sw = [Diagnostics.Stopwatch]::StartNew()

    # Get the new and old checksums
    [Nullable[int]]$oldchecksum = $null
    [Nullable[int]]$newchecksum = $null
    if ($SyncObject.ChecksumQueryText) {
        Write-Output 'Start: Checksum'; $sw.Restart()
        $oldchecksum = $SyncObject.LastSyncChecksum | ConvertFrom-DBNull
        $checksumQuery = "SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; {0}" -f $SyncObject.ChecksumQueryText
        $newchecksum = Invoke-DbaQuery $SourceSqlConnection -Query $checksumQuery -As SingleValue | ConvertFrom-DBNull
        Write-Output "Old checksum: ${oldchecksum}"
        Write-Output "New checksum: ${newchecksum}"
        Write-Output "Done: Checksum [$($sw.Elapsed)]"
    }

    <# If the checksums are different
        or) if the old checksum is null (meaning it has never been run, or run always)
        or) there is no ChecksumQueryText (meaning disable checksum usage)
        then run
    #>
    if (($oldchecksum -ne $newchecksum) -or ($null -eq $oldchecksum) -or ($null -eq $SyncObject.ChecksumQueryText)) {
        # Use the export query path override otherwise use the default - select *
        $exportQuery = if ($SyncObject.ExportQueryPath) {
            Get-Content -LiteralPath (Join-Path $current_path 'dependencies\SQL' $SyncObject.ExportQueryPath) -Raw
        } else {
            'SELECT _CollectionDate = SYSUTCDATETIME(), * FROM {0};' -f $SyncObject.SyncObjectNameClean
        }
        $exportQuery = "SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; {0}" -f $exportQuery

        # Set sync type (simple/complex)
        $syncType = switch ($true) {
            {($SyncObject.ImportProcClean) -and ($null -eq $SyncObject.ImportTableClean)} { 'Complex' }
            {($null -eq $SyncObject.ImportProcClean) -and ($SyncObject.ImportTableClean)} { 'Simple' }
            Default { throw "[$($SyncObject.SyncObjectName)] Invalid configuration" }
        }

        <#  For Table Valued Parameters:
            .NET documentation recommends using a DataTable

            For Write-DbaDbTableData:
            dbatools documentation recommends using a DataSet
            > Use DataSet for optimal performance as all records import in a single SqlBulkCopy call.
            > DataTable also performs well but avoid piping directly as it converts to slower DataRow processing.
        #>
        Write-Output 'Start: Export'; $sw.Restart()
        # using DataSet here because it's easy to pull the DataTable out of it
        $data_src = Invoke-DbaQuery $SourceSqlConnection -Query $exportQuery -As DataSet
        Write-Output "Done: Export [$($sw.Elapsed)]"

        switch ($syncType) {
            'Complex' {
                if ($data_src.Tables[0].Rows.Count -gt 0) {
                    # Create empty datatable in the shape of the target table type, merge the source data into it, then prep the TVP
                    $data_dst = Invoke-DbaQuery $TargetSqlConnection -Query ('DECLARE @x {0}; SELECT * FROM @x;' -f $SyncObject.ImportTypeClean) -As DataSet
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
                    Write-Output 'Start: Write'; $sw.Restart()
                    Invoke-DbaQuery $TargetSqlConnection -CommandType StoredProcedure -Query $SyncObject.ImportProcClean -QueryTimeout 30 `
                                    -SqlParameter @(
                                        $sqlParamImportID
                                        , (New-DbaSqlParameter -ParameterName 'Dataset' -SqlDbType Structured -Value $data_dst.Tables[0] -TypeName $SyncObject.ImportTypeClean)
                                        , (New-DbaSqlParameter -ParameterName 'Verbose' -SqlDbType Bit -Value $VerboseLog)
                                    )
                    Write-Output "Done: Write [$($sw.Elapsed)]"
                } else {
                    Write-Output 'Skip: Write - No data to import'
                }
            }
            'Simple' {
                # There's no way to know whether the export having zero records is intentional or not
                # For example, it could be a list of database errors...if their are none, then running the delete is correct
                Write-Output 'Start: Delete'; $sw.Restart()
                $null = Invoke-DbaQuery $TargetSqlConnection -Query 'import.usp_SyncObject_SimpleDelete' -CommandType StoredProcedure `
                                        -SqlParameter @{
                                            SyncObjectID = $SyncObject.SyncObjectID
                                            InstanceID   = $SyncObject._InstanceID
                                            DatabaseID   = $SyncObject._DatabaseID
                                            Verbose      = $VerboseLog
                                        }
                Write-Output "Done: Delete [$($sw.Elapsed)]"

                if ($data_src.Tables[0].Rows.Count -gt 0) {
                    Write-Output 'Start: Write'; $sw.Restart()

                    # Create empty datatable in the shape of the target table, add instance/database id column, then merge ithe source data into it
                    $data_dst = Invoke-DbaQuery $TargetSqlConnection -Query ('SELECT TOP(0) * FROM {0};' -f $SyncObject.ImportTableClean) -As DataSet
                    $data_src.Tables[0].Columns.Add([System.Data.DataColumn]::new('_InstanceID', [Int], $SyncObject._InstanceID))
                    $data_src.Tables[0].Columns.Add([System.Data.DataColumn]::new('_DatabaseID', [Int], $SyncObject._DatabaseID))
                    $data_dst.Tables[0].Merge($data_src.Tables[0], $false, [System.Data.MissingSchemaAction]::Ignore)

                    Write-DbaDbTableData -InputObject $data_dst -SqlInstance $TargetSqlConnection -Table $SyncObject.ImportTableClean
                    Write-Output "Done: Write [$($sw.Elapsed)]"
                } else {
                    Write-Output 'Skip: Write - No data to import'
                }
            }
        }
    } else {
        Write-Output 'Skipping sync: Checksums match'
    }
} catch {
    $errorMsg = Get-Error $_ | Out-String
    Write-Output "Error: ${errorMsg}"
} finally {
    Write-Output 'Checking in SyncObjectStatus'
    if ($oldchecksum -ne $newchecksum) { Write-Output "Set new checksum: ${newchecksum}" }
    Invoke-DbaQuery $TargetSqlConnection -CommandType StoredProcedure -Query 'import.usp_SetSyncStatus' `
                    -SqlParameter @{
                        InstanceID   = $SyncObject._InstanceID
                        DatabaseID   = $SyncObject._DatabaseID
                        SyncObjectID = $SyncObject.SyncObjectID
                        Checksum     = $newchecksum
                        ErrorMessage = $errorMsg
                        Verbose      = $true
                    } | Write-Output
}
Write-Output "Done: Sync [$($sw_syncItem.Elapsed)]"