[CmdletBinding()]
param (
    [Parameter(Position=0, Mandatory)][pscustomobject]$syncItem,
    [Parameter(Position=1, Mandatory)][Microsoft.SqlServer.Management.Smo.Server]$SourceSqlConnection,
    [Parameter(Position=2, Mandatory)][Microsoft.SqlServer.Management.Smo.Server]$TargetSqlConnection
)

$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues= @{
    'Write-DbaDbTableData:EnableException' = $true
    'Invoke-DbaQuery:EnableException' = $true
    'Invoke-DbaQuery:QueryTimeout' = 300
    'Invoke-DbaQuery:MessagesToOutput' = $true
}

#################################################
# Helper functions
#################################################

. "${PSScriptRoot}\shared.ps1"

#################################################

$sw_syncItem = [Diagnostics.Stopwatch]::StartNew()
Write-Output 'Start: Sync'

$InstanceID = $syncList[0].InstanceID
$DatabaseID = $syncList[0].DatabaseID

# Creating as script blocks due to bug in dbatools (Invoke-DbaAsync), it does not clear the parameters on the SqlCommand after use
$sqlParamInstance = { New-DbaSqlParameter -ParameterName 'InstanceID' -SqlDbType Int -Value $InstanceID }
$sqlParamDatabase = { New-DbaSqlParameter -ParameterName 'DatabaseID' -SqlDbType Int -Value ($DatabaseID ?? [DBNull]::Value) }

try {
    # Get the new and old checksums
    [Nullable[int]]$oldchecksum = $null
    [Nullable[int]]$newchecksum = $null
    if ($syncItem.ChecksumQueryText) {
        Write-Output 'Start: Get checksums'
        $oldchecksum = $syncItem.LastSyncChecksum | ConvertFrom-DBNull
        Write-Output "Old checksum: ${oldchecksum}"
        $checksumQuery = "SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; {0}" -f $syncItem.ChecksumQueryText
        $newchecksum = Invoke-DbaQuery $SourceSqlConnection -Query $checksumQuery -As SingleValue | ConvertFrom-DBNull
        Write-Output "New checksum: ${newchecksum}"
        Write-Output 'Done: Get checksums'
    }

    <# If the checksums are different
        or) if the old checksum is null (meaning it has never been run, or run always)
        or) there is no ChecksumQueryText (meaning disable checksum usage)
        then run
    #>
    if (($oldchecksum -ne $newchecksum) -or ($null -eq $oldchecksum) -or ($null -eq $syncItem.ChecksumQueryText)) {
        # Use the export query path override otherwise use the default - select *
        if ($syncItem.ExportQueryPath) {
            $exportQuery = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'SQL' $syncItem.ExportQueryPath)
        } else {
            $exportQuery = 'SELECT _CollectionDate = SYSUTCDATETIME(), * FROM {0}' -f $syncItem.SyncObjectName
        }
        $exportQuery = "SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; ${exportQuery}"

        switch ($syncItem.SyncObjectLevelID) {
            1 {
                $deleteQuery = 'DELETE {0} WHERE _InstanceID = @InstanceID' -f $syncItem.ImportTable
                $column = [System.Data.DataColumn]::new('_InstanceID', [Int], $InstanceID)
                $sqlParamImportID = $sqlParamInstance
            }
            2 {
                $deleteQuery = 'DELETE {0} WHERE _DatabaseID = @DatabaseID' -f $syncItem.ImportTable
                $column = [System.Data.DataColumn]::new('_DatabaseID', [Int], $DatabaseID)
                $sqlParamImportID = $sqlParamDatabase
            }
            Default { throw "[$($syncItem.SyncObjectName)] Invalid SyncObjectLevelID" }
        }

        $sw = [Diagnostics.Stopwatch]::StartNew()

        if (($syncItem.ImportProc) -and ($null -eq $syncItem.ImportTable)) {

            Write-Output 'Sync object using proc and table type'

            Write-Output 'Start: Export'; $sw.Restart()
            $data = Invoke-DbaQuery $SourceSqlConnection -Query $exportQuery -As DataTable
            Write-Output "Done: Export [$($sw.Elapsed)]"

            # No delete step because the import proc will handle it - deletes, updates, etc
            if ($data.Rows.Count -gt 0) {
                Write-Output 'Start: Write'; $sw.Restart()
                $sqlParamData = New-DbaSqlParameter -ParameterName 'Dataset' -SqlDbType Structured -Value $data -TypeName $syncItem.ImportType
                Invoke-DbaQuery $TargetSqlConnection -CommandType StoredProcedure -Query $syncItem.ImportProc -SqlParameter @((&$sqlParamImportID), $sqlParamData) | Write-Output
                Write-Output "Done: Write [$($sw.Elapsed)]"
            } else {
                Write-Output 'Skip: Write - No data to import'
            }

        } elseif (($null -eq $syncItem.ImportProc) -and ($syncItem.ImportTable)) {

            Write-Output 'Sync object directly using delete and insert'

            Write-Output 'Start: Export'; $sw.Restart()
            $data = Invoke-DbaQuery $SourceSqlConnection -Query $exportQuery -As DataSet
            Write-Output "Done: Export [$($sw.Elapsed)]"

            # There's no way to know whether the export having zero records is intentional or not
            # For example, it could be a list of database errors...if their are none, then running the delete is correct
            Write-Output 'Start: Delete'; $sw.Restart()
            $null = Invoke-DbaQuery $TargetSqlConnection -Query $deleteQuery -SqlParameter @((&$sqlParamInstance), (&$sqlParamDatabase))
            Write-Output "Done: Delete [$($sw.Elapsed)]"

            if ($data.Tables[0].Rows.Count -gt 0) {
                Write-Output 'Start: Write'; $sw.Restart()
                Write-Output 'Add InstanceID/DatabaseID column to DataTable'
                $data.Tables[0].Columns.Add($column); $column.SetOrdinal(0)

                <# Really odd behavior with sys.dm_os_enumerate_fixed_drives. Kept running into all sorts of
                issues with using a DataTable vs DataSet. Tried using an exportQueryPath, the filename could
                not contain `dm_os_enumerate_fixed_drives` or it would throw an exception. The only solution
                I could find was by pulling a DataTable out of a DataSet object #>
                if ($syncItem.SyncObjectName -eq 'sys.dm_os_enumerate_fixed_drives') {
                    Write-Output 'Special case handling: converting DataSet to single DataTable'
                    $data = $data.Tables[0]
                }

                Write-DbaDbTableData -InputObject $data -SqlInstance $TargetSqlConnection -Table $syncItem.ImportTable
                Write-Output "Done: Write [$($sw.Elapsed)]"
            } else {
                Write-Output 'Skip: Write - No data to import'
            }

        } else {
            throw "[$($syncItem.SyncObjectName)] Invalid configuration"
        }
    } else {
        Write-Output 'Skipping sync: Checksums match'
    }
} catch {
    Write-Output 'sync_object_process.ps1 - catch block'
    Write-Output ($_.Exception.InnerException.Errors.Message -join ' ')
    $errorMsg = Get-Error $_ | Out-String
} finally {
    Write-Output 'Checking in SyncObjectStatus'
    if ($oldchecksum -ne $newchecksum) { Write-Output "Set new checksum: ${newchecksum}" }
    Invoke-DbaQuery $TargetSqlConnection -CommandType StoredProcedure -Query 'import.usp_SetSyncStatus' `
                    -SqlParameter @((&$sqlParamInstance), (&$sqlParamDatabase)
                        , (New-DbaSqlParameter -ParameterName 'SyncObjectID' -SqlDbType Int -Value $syncItem.SyncObjectID)
                        , (New-Object 'Microsoft.Data.SqlClient.SqlParameter' @('Checksum', [Data.SqlDbType]::Int) -Property @{Value = $newchecksum}) # Bug in dbatools, falsy values are ignored and parameter is not passed in
                        , (New-DbaSqlParameter -ParameterName 'ErrorMessage' -SqlDbType NVarChar -Value $errorMsg)
                    ) | Write-Output
}
Write-Output "Done: Sync [$($sw_syncItem.Elapsed)]"