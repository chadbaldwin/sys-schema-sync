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
    'Invoke-DbaQuery:MessagesToOutput' = $true
}

$script_to_run = Get-Item -LiteralPath (Join-Path $PSScriptRoot 'sync_object_process.ps1')
##################################################

##################################################
try {
    $ts = Measure-Command {
        $conn_dst = Connect-DbaInstance -ConnectionString $Config.RepositoryDatabaseConnectionString
    }
    if ($VerboseLog) { Write-Output "Connected to destination database [${ts}]" }

    try {
        $ts = Measure-Command {
            $conn_src = Connect-DbaInstance $SqlInstance -Database $SqlDatabase -MultiSubnetFailover
        }
        if ($VerboseLog) { Write-Output "Connected to source database [${ts}]" }
    } catch {
        Write-Output ("Failed to connect to [$($SqlInstance)].[$($SqlDatabase)]. Exception: " + ($_.Exception.InnerException.Errors.Message -join ' '))
        # If we fail to even connect to the DB, then log an error at the DB level, thus pushing all syncs to next run interval
        $errorMsg = Get-Error $_ | Out-String
        Invoke-DbaQuery $conn_dst -CommandType StoredProcedure -Query 'import.usp_SetSyncStatus' `
                        -SqlParameter @{
                            InstanceID   = $SyncObjects[0]._InstanceID
                            DatabaseID   = $SyncObjects[0]._DatabaseID
                            ErrorMessage = $errorMsg
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
    Write-Output "Exception: $(Get-Error $_ | Out-String)"
    Write-Output ($_.Exception.InnerException.Errors.Message -join ' ')
} finally {
    $conn_src, $conn_dst | Disconnect-DbaInstance | Out-Null
}