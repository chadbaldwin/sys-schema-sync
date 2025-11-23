#Requires -PSEdition Core -Version 7.2 -Modules @{ ModuleName="dbatools"; ModuleVersion="2.1.7" }

[CmdletBinding()]
param (
    [Parameter(Mandatory, Position=0)][string]$SqlInstance,
    [Parameter(Mandatory, Position=1)][string]$SqlDatabase,
    [Parameter(Mandatory, Position=2)][pscustomobject[]]$SyncObjects,
    [Parameter(Mandatory, Position=3)][System.Collections.Hashtable]$Config
)

$VerboseLog = $Config.VerboseLog

$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues= @{
    'Invoke-DbaQuery:EnableException' = $true
    'Invoke-DbaQuery:QueryTimeout' = 30
    'Connect-DbaInstance:ConnectTimeout' = 30
    'Invoke-DbaQuery:MessagesToOutput' = $true
}

$script_to_run = Get-Item -LiteralPath (Join-Path $PSScriptRoot 'sync_object_process.ps1')
##################################################

##################################################
try {
    if ($VerboseLog) { Write-Output "Attempting to connect to repository database" }
    $ts = Measure-Command {
        $conn_dst = Connect-DbaInstance -ConnectionString $Config.RepositoryDatabaseConnectionString
    }
    if ($VerboseLog) { Write-Output "Connected to destination database [${ts}]" }

    try {
        if ($VerboseLog) { Write-Output "Attempting to connect to source database [${SqlInstance}].[${SqlDatabase}]" }
        $ts = Measure-Command {
            $conn_src = Connect-DbaInstance $SqlInstance -Database $SqlDatabase -MultiSubnetFailover
        }
        if ($VerboseLog) { Write-Output "Connected to source database [${ts}]" }
    } catch {
        $errorStr = Get-Error $_ | Out-String
        $errorMsg = $_.Exception.Message
        $errorOutput = "Error: Failed to connect to source database: [$($SqlInstance)].[$($SqlDatabase)]. Exception: ${errorMsg} ${errorStr}"
        Write-Output $errorOutput
        # If we fail to even connect to the DB, then log an error at the DB level, thus pushing all syncs to next run interval
        Invoke-DbaQuery $conn_dst -CommandType StoredProcedure -Query 'import.usp_SetSyncStatus' `
                        -SqlParameter @{
                            InstanceID   = $SyncObjects[0]._InstanceID
                            DatabaseID   = $SyncObjects[0]._DatabaseID
                            ErrorMessage = $errorStr ? $errorOutput : $null
                            Verbose      = $VerboseLog
                         } | Write-Output
        return
    }

    foreach ($syncObject in $SyncObjects) {
        $key = "[$($syncObject.SyncObjectName)]"
        & $script_to_run $syncObject $conn_src $conn_dst $config |
            ForEach-Object { Write-Output "${key} ${_}" }
    }
} catch {
    $errorStr = Get-Error $_ | Out-String
    $errorMsg = $_.Exception.Message
    Write-Output "Error: ${errorMsg} ${errorStr}"
} finally {
    $conn_src, $conn_dst | Disconnect-DbaInstance | Out-Null
}