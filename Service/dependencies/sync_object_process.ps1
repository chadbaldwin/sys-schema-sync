#Requires -PSEdition Core -Version 7.2 -Modules @{ ModuleName="dbatools"; ModuleVersion="2.1.7" }

[CmdletBinding()]
param (
    [Parameter(Mandatory, Position=0)][pscustomobject]$SyncObject,
    [Parameter(Mandatory, Position=1)][Microsoft.SqlServer.Management.Smo.Server]$SourceSqlConnection,
    [Parameter(Mandatory, Position=2)][Microsoft.SqlServer.Management.Smo.Server]$TargetSqlConnection,
    [Parameter(Mandatory, Position=3)][System.Collections.Hashtable]$Config
)

$ErrorActionPreference = 'Stop'

$current_path = ([string]::IsNullOrWhiteSpace($PSScriptRoot) ? $PWD.Path : $PSScriptRoot) | Split-Path -Parent -Resolve

$VerboseLog = $Config.VerboseLog

$PSDefaultParameterValues= @{
    'Invoke-DbaQuery:EnableException' = $true
    'Invoke-DbaQuery:MessagesToOutput' = $true
    'Invoke-DbaQuery:QueryTimeout' = 60
    'Connect-DbaInstance:ConnectTimeout' = 30
    'Write-DbaDbTableData:EnableException' = $true
}

#################################################
# Helper functions
#################################################

function Write-Log {
    param (
        [Parameter(Mandatory, Position=0, ValueFromPipeline)][string]$Message,
        [Parameter(Position=1)][switch]$Force
    )
    process {
        if ($VerboseLog -or $Force) {
            Write-Output $Message
        }
    }
}

function ConvertFrom-DBNull {
    param ([Parameter(Position=0, ValueFromPipeline=$true)][object]$value)
    process { $value -is [DBNull] ? $null : $value }
}

# TODO: Figure out if there's a way do do this client side. Having to reach out to SQL Server for this is overkill
# TODO: Or, maybe just pass in a SyncObjectID and it returns all the cleaned values in one go? This would allow getting rid of Get-TVPTypeFromProcName
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

    Invoke-DbaQuery $SqlConnection -Query $query -As SingleValue -SqlParameter @{ ProcName = $ProcName }
}

<# 
   Usage:
   . Invoke-TimedScriptBlock 'Label' {
       # code to time
   }

   The function will execute the scriptblock while including start/done logging with elapsed time.

   Dot-sourcing this function will allow side-effects in the current scope.
   Intended to be a substitution for Measure-Command with logging and still
   calculates a timespan even when there's an exception.

   The function was written this way to avoid creating or affecting any local variables.

   If you dot-source a function, even the parameter variables become available in the
   calling scope. So to avoid this, we're using $PSBoundParameters as a hack.

   And no, not even `$Private:` or `$Script:` scopes help here.
#>
function Invoke-TimedScriptBlock {
    if ($args.Count -ne 2) { throw 'Args must contain two parameters - string, scriptblock'; return }

    if ($args[0] -isnot [string]) { throw 'Args[0] must be a string' }
    if ($args[1] -isnot [scriptblock]) { throw 'Args[0] must be a scriptblock' }

    $PSBoundParameters['label'] = $args[0]
    $PSBoundParameters['scriptblock'] = $args[1]
    $PSBoundParameters['sw'] = [Diagnostics.Stopwatch]::StartNew()

    Write-Log "Start: $($PSBoundParameters['label'])"

    try {
        . $PSBoundParameters['scriptblock']
        Write-Log "Done: $($PSBoundParameters['label']) [$($PSBoundParameters['sw'].Elapsed)]"
    } catch {
        Write-Log "Error: $($PSBoundParameters['label']) [$($PSBoundParameters['sw'].Elapsed)]"
        throw
    }
}

#################################################

Invoke-TimedScriptBlock 'Sync' {
    try {
        $queryPrefix = (
            'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;',
            'SET NOCOUNT ON;',
            'SET DEADLOCK_PRIORITY -10;',
            'SET LOCK_TIMEOUT 30000;',
            '{0}'
        ) -join "`r`n"

        # Get the new and old checksums
        [Nullable[int]]$newchecksum = $null
        if ($SyncObject.ChecksumQueryText) {
            . Invoke-TimedScriptBlock 'Checksum' {
                $newchecksum = Invoke-DbaQuery $SourceSqlConnection -Query ($queryPrefix -f $SyncObject.ChecksumQueryText) -As SingleValue `
                                               -SqlParameter @{ LastSyncTime = $SyncObject.LastSyncTime } | ConvertFrom-DBNull
                Write-Log "Old checksum: $($SyncObject.LastSyncChecksum)"
                Write-Log "New checksum: ${newchecksum}"
            }
        }

        if (
            (($SyncObject.LastSyncChecksum -ne $newchecksum) -and (($newchecksum -ne 0) -or $SyncObject.SyncOnZeroChecksum)) -or # If the checksums are different (and the new checksum is not zero unless SyncOnZeroChecksum is true)
            ($null -eq $SyncObject.LastSyncChecksum) -or                                                                         # or) if the old checksum is null (meaning it has never been run, or run always)
            ($null -eq $SyncObject.ChecksumQueryText)                                                                            # or) there is no ChecksumQueryText (meaning disable checksum usage)
        ) {
            # Get cleansed identifiers
            $Clean = Get-CleanSqlIdentifiers -SyncObject $SyncObject -SqlConnection $TargetSqlConnection

            # Use the export query path override otherwise use the default - select *
            $exportQuery =  $SyncObject.ExportQueryPath ?
                                (Get-Content -LiteralPath (Join-Path $current_path 'dependencies\SQL' $SyncObject.ExportQueryPath) -Raw) :
                                ('SELECT _CollectionDate = SYSUTCDATETIME(), * FROM {0};' -f $Clean.SyncObjectNameClean)
            $exportQuery = $queryPrefix -f $exportQuery

            # Set sync type (simple/complex)
            $syncType = switch ($true) {
                {($Clean.ImportProcClean) -and ($null -eq $Clean.ImportTableClean)} { 'Complex' }
                {($null -eq $Clean.ImportProcClean) -and ($Clean.ImportTableClean)} { 'Simple' }
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
            . Invoke-TimedScriptBlock 'Export' {
                # using DataSet here because it's easy to pull the DataTable out of it
                $data_src = Invoke-DbaQuery $SourceSqlConnection -Query $exportQuery -As DataSet
            }

            switch ($syncType) {
                'Complex' {
                    if ($data_src.Tables[0].Rows.Count -gt 0) {
                        # No delete step because the import proc will handle it - deletes, updates, etc
                        Invoke-TimedScriptBlock 'Write' {
                            $ImportTypeClean = Get-TVPTypeFromProcName $Clean.ImportProcClean $TargetSqlConnection

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

                            Invoke-DbaQuery $TargetSqlConnection -CommandType StoredProcedure -Query $Clean.ImportProcClean -QueryTimeout 180 `
                                            -SqlParameter @(
                                                $sqlParamImportID
                                                , (New-DbaSqlParameter -ParameterName 'Dataset' -SqlDbType Structured -Value $data_dst.Tables[0] -TypeName $ImportTypeClean)
                                                , (New-DbaSqlParameter -ParameterName 'Verbose' -SqlDbType Bit -Value $VerboseLog)
                                            )
                        }
                    } else {
                        Write-Log 'Skip: Write - No data to import'
                    }
                }
                'Simple' {
                    # There's no way to know whether the export having zero records is intentional or not
                    # For example, it could be a list of database errors...if their are none, then running the delete is correct
                    Invoke-TimedScriptBlock 'Delete' {
                        $null = Invoke-DbaQuery $TargetSqlConnection -Query 'import.usp_SyncObject_SimpleDelete' -CommandType StoredProcedure -QueryTimeout 180 `
                                                -SqlParameter @{
                                                    SyncObjectID = $SyncObject.SyncObjectID
                                                    InstanceID   = $SyncObject._InstanceID
                                                    DatabaseID   = $SyncObject._DatabaseID
                                                    Verbose      = $VerboseLog
                                                }
                    }

                    if ($data_src.Tables[0].Rows.Count -gt 0) {
                        Invoke-TimedScriptBlock 'Write' {
                            <# Add instance/database id columns to source data before merging
                               It's safe to add both columns because we're using merge with the Ignore missing schema action.
                               If the destination datatable doesn't have one of these columns, it will simply be ignored. #>
                            $data_src.Tables[0].Columns.Add([System.Data.DataColumn]::new('_InstanceID', [Int], $SyncObject._InstanceID))
                            $data_src.Tables[0].Columns.Add([System.Data.DataColumn]::new('_DatabaseID', [Int], $SyncObject._DatabaseID))

                            # Create empty datatable in the shape of the target table, then merge the source data into it.
                            $data_dst = Invoke-DbaQuery $TargetSqlConnection -Query ('SELECT TOP(0) * FROM {0};' -f $Clean.ImportTableClean) -As DataSet
                            $data_dst.Tables[0].Merge($data_src.Tables[0], $false, [System.Data.MissingSchemaAction]::Ignore)

                            Write-DbaDbTableData -InputObject $data_dst -SqlInstance $TargetSqlConnection -Table $Clean.ImportTableClean -BulkCopyTimeOut 180
                        }
                    } else {
                        Write-Log 'Skip: Write - No data to import'
                    }
                }
            }
        } else {
            Write-Log 'Skip: Sync - Checksums match'
        }
    } catch {
        $errorStr = Get-Error $_ | Out-String
        $errorMsg = $_.Exception.Message
        Write-Output "Error: ${errorMsg} ${errorStr}"
    } finally {
        Invoke-DbaQuery $TargetSqlConnection -CommandType StoredProcedure -Query 'import.usp_SetSyncStatus' `
                        -SqlParameter @{
                            InstanceID   = $SyncObject._InstanceID
                            DatabaseID   = $SyncObject._DatabaseID
                            SyncObjectID = $SyncObject.SyncObjectID
                            Checksum     = $newchecksum
                            ErrorMessage = $errorStr ? "Error: ${errorMsg} ${errorStr}" : $null
                            Verbose      = $VerboseLog
                        } | Write-Log -Force
    }
    $VerboseLog = $true # hack to ensure 'Done: Sync' message is always printed
}