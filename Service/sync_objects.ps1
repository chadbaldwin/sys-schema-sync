#Requires -PSEdition Core -Version 7.0 -Modules @{ ModuleName="dbatools"; ModuleVersion="2.1.7" }

[CmdletBinding()]
param (
    [Parameter(Mandatory,Position=0)][string]$SqlInstance,
    [Parameter(Mandatory,Position=1)][string]$SqlDatabase
)

$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues= @{
    'Write-DbaDbTableData:EnableException' = $true
    'Invoke-DbaQuery:EnableException' = $true
    'Invoke-DbaQuery:QueryTimeout' = 300
    'Invoke-DbaQuery:MessagesToOutput' = $true
}

# Get script configuration
$config = Get-Content -LiteralPath "${PSScriptRoot}\appsettings.jsonc" -Raw | ConvertFrom-Json
##################################################

##################################################
$conn_tgt = Connect-DbaInstance -ConnectionString $config.RepositoryDatabaseConnectionString

Write-Output 'Getting list of syncs to run for DB'

$query = @'
    -- Throwing in some sql injection protection - still need to figure out how to handle the ChecksumQueryText
    SELECT _InstanceID, _DatabaseID, SyncObjectID, SyncObjectName, SyncObjectLevelID, LastSyncChecksum
        , SyncObjectNameClean = QUOTENAME(PARSENAME(q.SyncObjectName, 2)) + '.' + QUOTENAME(PARSENAME(q.SyncObjectName, 1))
        , ImportTableClean    = QUOTENAME(PARSENAME(q.ImportTable   , 2)) + '.' + QUOTENAME(PARSENAME(q.ImportTable   , 1))
        , ImportProcClean     = QUOTENAME(PARSENAME(q.ImportProc    , 2)) + '.' + QUOTENAME(PARSENAME(q.ImportProc    , 1))
        , ImportTypeClean     = QUOTENAME(PARSENAME(q.ImportType    , 2)) + '.' + QUOTENAME(PARSENAME(q.ImportType    , 1))
        , ExportQueryPath, ChecksumQueryText
    FROM import.vw_DatabaseSyncObjectQueue q
    WHERE InstanceName = @InstanceName
        AND DatabaseName = @DatabaseName;
'@

$syncList = Invoke-DbaQuery $conn_tgt -Query $query -As PSObject `
                            -SqlParameter @(
                                , (New-DbaSqlParameter -ParameterName 'InstanceName' -SqlDbType NVarChar -Value $SqlInstance)
                                , (New-DbaSqlParameter -ParameterName 'DatabaseName' -SqlDbType NVarChar -Value $SqlDatabase)
                            )

if ($null -eq $syncList) {
    Write-Output 'No syncs to run'
    $conn_tgt | Disconnect-DbaInstance | Out-Null
    return
}
##################################################

##################################################
try {
    try {
        $conn_src = Connect-DbaInstance $SqlInstance -Database $SqlDatabase -MultiSubnetFailover
    } catch {
        Write-Output ("Failed to connect to [$($SqlInstance)].[$($SqlDatabase)]. Exception: " + ($_.Exception.InnerException.Errors.Message -join ' '))
        # If we fail to even connect to the DB, then log an error at the DB level, thus pushing all syncs to next run interval
        $errorMsg = Get-Error $_ | Out-String
        Invoke-DbaQuery $conn_tgt -CommandType StoredProcedure -Query 'import.usp_SetSyncStatus' `
                        -SqlParameter @(
                              (New-DbaSqlParameter -ParameterName 'InstanceID'   -SqlDbType Int      -Value $syncList[0]._InstanceID)
                            , (New-DbaSqlParameter -ParameterName 'DatabaseID'   -SqlDbType Int      -Value ($syncList[0]._DatabaseID ?? [DBNull]::Value))
                            , (New-DbaSqlParameter -ParameterName 'ErrorMessage' -SqlDbType NVarChar -Value $errorMsg)
                        ) | Write-Output
        return
    }

    foreach ($syncItem in $syncList) {
        $key = "[$($syncItem.SyncObjectName)]"
        & .\sync_object_process.ps1 -syncItem $syncItem -SourceSqlConnection $conn_src -TargetSqlConnection $conn_tgt |
            % { Write-Output "${key} ${_}" }
    }
} catch {
    Write-Output "Exception: $(Get-Error $_ | Out-String)"
    Write-Output ($_.Exception.InnerException.Errors.Message -join ' ')
} finally {
    $conn_src, $conn_tgt | Disconnect-DbaInstance | Out-Null
}
