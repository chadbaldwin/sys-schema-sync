#Requires -PSEdition Core -Version 7.2 -Modules @{ ModuleName="dbatools"; ModuleVersion="2.1.7" }

[CmdletBinding()]
param (
    [Parameter(Mandatory, Position=0)][string]$SqlInstance,
    [Parameter(Mandatory, Position=1)][string]$SqlDatabase,
    [Parameter(Mandatory, Position=2)][pscustomobject[]]$SyncObjects,
    [Parameter(Mandatory, Position=3)][System.Collections.Hashtable]$Config
)

$ErrorActionPreference = 'Stop'

$current_path = ([string]::IsNullOrWhiteSpace($PSScriptRoot) ? $PWD.Path : $PSScriptRoot) | Split-Path -Parent -Resolve

$VerboseLog = $Config.VerboseLog

$PSDefaultParameterValues= @{
    'Invoke-DbaQuery:EnableException' = $true
    'Invoke-DbaQuery:MessagesToOutput' = $true
    'Invoke-DbaQuery:QueryTimeout' = 30
    'Connect-DbaInstance:ConnectTimeout' = 30
}

$script_to_run = Get-Item -LiteralPath (Join-Path $current_path '\dependencies\sync_object_process.ps1')

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

##################################################

##################################################
$sw = [Diagnostics.Stopwatch]::StartNew()

try {
    # Connect to repository database
    Write-Log "Attempting to connect to repository database"; $sw.Restart()
    $conn_dst = Connect-DbaInstance -ConnectionString $Config.RepositoryDatabaseConnectionString
    Write-Log "Connected to destination database [$($sw.Elapsed)]"

    # Connect to source database
    try {
        Write-Log "Attempting to connect to source database [${SqlInstance}].[${SqlDatabase}]"; $sw.Restart()
        $conn_src = Connect-DbaInstance $SqlInstance -Database $SqlDatabase -MultiSubnetFailover
        Write-Log "Connected to source database [$($sw.Elapsed)]"
   } catch {
        $errorStr = Get-Error $_ | Out-String
        $errorMsg = $_.Exception.Message
        $errorOutput = "Error: Failed to connect to source database: [$($SqlInstance)].[$($SqlDatabase)]. Exception: ${errorMsg} ${errorStr}"
        Write-Log $errorOutput -Force

        # If we fail to even connect to the DB, then log an error at the DB level, thus pushing all syncs to next run interval
        Invoke-DbaQuery $conn_dst -CommandType StoredProcedure -Query 'import.usp_SetSyncStatus' `
                        -SqlParameter @{
                            InstanceID   = $SyncObjects[0]._InstanceID
                            DatabaseID   = $SyncObjects[0]._DatabaseID
                            ErrorMessage = $errorStr ? $errorOutput : $null
                            Verbose      = $VerboseLog
                         } | Write-Log -Force
        return
    }

    foreach ($syncObject in $SyncObjects) {
        & $script_to_run $syncObject $conn_src $conn_dst $config |
            ForEach-Object { Write-Log "[$($syncObject.SyncObjectName)] ${_}" -Force }
    }
} catch {
    $errorStr = Get-Error $_ | Out-String
    $errorMsg = $_.Exception.Message
    Write-Log "Error: ${errorMsg} ${errorStr}" -Force
} finally {
    $conn_src, $conn_dst | Disconnect-DbaInstance | Out-Null
}