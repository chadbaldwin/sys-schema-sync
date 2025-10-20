#Requires -PSEdition Core -Version 7.2 -Modules @{ ModuleName="dbatools"; ModuleVersion="2.1.7" }

[CmdletBinding()]
param (
    [Parameter(Mandatory, Position=0)][string]$SqlInstance,
    [Parameter(Mandatory, Position=1)][string]$SqlDatabase,
    [Parameter(Mandatory, Position=2)][pscustomobject[]]$SyncObjects
)

$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues= @{
    'Write-DbaDbTableData:EnableException' = $true
    'Invoke-DbaQuery:EnableException' = $true
    'Invoke-DbaQuery:QueryTimeout' = 30
    'Invoke-DbaQuery:MessagesToOutput' = $true
}

$current_path = Get-Item ([string]::IsNullOrWhiteSpace($PSScriptRoot) ? $PWD.Path : $PSScriptRoot)
$current_path = $current_path.Parent

# Get script configuration
$config = Get-Content -LiteralPath "${current_path}\appsettings.jsonc" -Raw | ConvertFrom-Json
##################################################

##################################################
$conn_tgt = Connect-DbaInstance -ConnectionString $config.RepositoryDatabaseConnectionString

Write-Output 'Getting list of syncs to run for DB'

if ($null -eq $SyncObjects) {
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
                              (New-DbaSqlParameter -ParameterName 'InstanceID'   -SqlDbType Int      -Value $SyncObjects[0]._InstanceID)
                            , (New-DbaSqlParameter -ParameterName 'DatabaseID'   -SqlDbType Int      -Value ($SyncObjects[0]._DatabaseID ?? [DBNull]::Value))
                            , (New-DbaSqlParameter -ParameterName 'ErrorMessage' -SqlDbType NVarChar -Value $errorMsg)
                            , (New-DbaSqlParameter -ParameterName 'Verbose'      -SqlDbType Bit      -Value 1)
                        ) | Write-Output
        return
    }

    foreach ($syncItem in $SyncObjects) {
        $key = "[$($syncItem.SyncObjectName)]"
        & .\dependencies\sync_object_process.ps1 -syncItem $syncItem -SourceSqlConnection $conn_src -TargetSqlConnection $conn_tgt |
            ForEach-Object { Write-Output "${key} ${_}" }
    }
} catch {
    Write-Output "Exception: $(Get-Error $_ | Out-String)"
    Write-Output ($_.Exception.InnerException.Errors.Message -join ' ')
} finally {
    $conn_src, $conn_tgt | Disconnect-DbaInstance | Out-Null
}
