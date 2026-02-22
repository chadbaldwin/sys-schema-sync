#Requires -PSEdition Core -Version 7.2 -Modules @{ ModuleName="dbatools"; ModuleVersion="2.1.7" }

$ErrorActionPreference = 'Stop'

# Setting current_path variable just to make it easier when running sections of this script ad-hoc
$current_path = [string]::IsNullOrWhiteSpace($PSScriptRoot) ? $PWD.Path : $PSScriptRoot

#################################################
# Load dbatools
#################################################

# Setting environment variables here will still get inherited by parallel child processes
# Disabling tab expansion (TEPP) and logging for dbatools helps improve concurrency performance
# Otherwise, with too many concurrent processes, dbatools will start returning warnings when failing to start the TEPP runspaces
$env:DBATOOLS_DISABLE_TEPP = $true
$env:DBATOOLS_DISABLE_LOGGING = $true
Import-Module -Name dbatools
$PSDefaultParameterValues= @{
    'Invoke-DbaQuery:EnableException' = $true
    'Connect-DbaInstance:ConnectTimeout' = 30
}

#################################################
# Load configuration
#################################################

# Get dependencies
$config = Get-Content -LiteralPath (Join-Path $current_path 'appsettings.jsonc') -Raw | ConvertFrom-Json -AsHashtable

# Set configuration defaults
$config.InstanceConcurrencyLimit         ??= 5
$config.DatabaseConcurrencyLimit         ??= 1
$config.VerboseLog                       ??= $false
$config.OpportunisticSchedulingEnabled   ??= $false
$config.OpportunisticSchedulingThreshold ??= 50
$config.QueueProcessingBatchSize         ??= 100
$config.LogDirectory                     ??= 'Logs'
$config.LogRetentionDays                 ??= 30
$config.ScriptToRun                        = Get-Item -LiteralPath (Join-Path $current_path 'dependencies\sync_objects.ps1')

$logdir = mkdir (Join-Path $current_path $config.LogDirectory) -Force

#################################################
# Helper functions
#################################################

<#
    Note: Add-Content is not thread-safe while writing to a file.
    If enough concurrent writes to the same file happen, they will start to step
    on each other and will cause some partially complete lines.

    https://github.com/PowerShell/PowerShell/issues/14416
#>
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Position=0,ValueFromPipeline)][object]$Message,
        [Parameter(Position=1)][string]$LogDirectory
    )

    process {
        $msg = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ${Message}"
        if ($LogDirectory) { $msg | Add-Content (Join-Path $LogDirectory "$(Get-Date -Format 'yyyy-MM-dd').log") }
        $msg | Write-Host
    }
}

$PSDefaultParameterValues['Write-Log:LogDirectory'] = $logdir

#################################################
# Log cleanup
#################################################

Write-Log 'Clean up old log files'
Get-ChildItem -Path $logdir -Filter '*.log' -File |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-($config.LogRetentionDays)) } |
    Remove-Item -Force -ErrorAction SilentlyContinue

#################################################
# Starting
#################################################

Write-Log '-------------------------------------------------'
Write-Log 'Starting...'
Write-Log "Concurrent instance throttle limit: $($config.InstanceConcurrencyLimit)"
Write-Log "Concurrent database throttle limit: $($config.DatabaseConcurrencyLimit)"
$sw = [Diagnostics.Stopwatch]::StartNew()

#################################################
# Get targets
#################################################

Write-Log 'Establishing connection to repository database'
try {
    $conn = Connect-DbaInstance -ConnectionString $config.RepositoryDatabaseConnectionString
} catch {
    $errorStr = Get-Error $_ | Out-String
    $errorMsg = $_.Exception.Message
    Write-Log "Error: Failed to connect to database. Exception: ${errorMsg} ${errorStr}"
    throw
}

Write-Log 'Getting list of instances and databases to run against'
try {
    $targets = Invoke-DbaQuery $conn -Query 'import.usp_GetDatabaseSyncObjectsToProcess' -CommandType StoredProcedure -As PSObject -QueryTimeout 30 `
            -SqlParameter @{
                Limit = $config.QueueProcessingBatchSize
                OpportunisticSchedulingEnabled = $config.OpportunisticSchedulingEnabled
                OpportunisticSchedulingThreshold = $config.OpportunisticSchedulingThreshold
            } |
        Group-Object InstanceName | ForEach-Object {
            [pscustomobject]@{
                Instance = $_.Name
                Databases = $_.Group | Group-Object DatabaseName |
                    ForEach-Object {
                        [pscustomobject]@{
                            Database = $_.Name
                            SyncObjects = $_.Group
                        }
                    }
            }
        }
} catch {
    $errorStr = Get-Error $_ | Out-String
    $errorMsg = $_.Exception.Message
    Write-Log "Error: Failed to get list of instances and databases to run against. Exception: ${errorMsg} ${errorStr}"
    throw
}

if ($targets.Count -eq 0) {
    Write-Log 'Done: Queue is empty, nothing to process.'
    Write-Log '-------------------------------------------------'
    return
}

Write-Log "Total instances: $($targets.Count); databases: $($targets.Databases.Count); sync tasks: $($targets.Databases.SyncObjects.Count)"

#################################################
# Main
#################################################

Write-Log 'Starting concurrent process against instances'
# Handles running instances in parallel
$targets | ForEach-Object -Parallel {
    $config = $using:config
    $sqlInstance = $_.Instance

    $sw_inst = [Diagnostics.Stopwatch]::StartNew()
    if ($config.VerboseLog) { Write-Output "[${sqlInstance}] Start: Instance [DB Count: $($_.Databases.Count)]" }

    # Handles running databases in parallel
    $_.Databases | ForEach-Object -Parallel {
        $config = $using:config
        $key = "[{0}].[{1}]" -f $using:sqlInstance, $_.Database

        function Write-Msg {
            param ([Parameter(Position=0,ValueFromPipeline)][object]$Message)
            process { Write-Output "${key} ${Message}" }
        }

        $sw_db = [Diagnostics.Stopwatch]::StartNew()
        if ($config.VerboseLog) { Write-Msg "Start: Database [Sync Object Count: $($_.SyncObjects.Count)]" }

        try {
            & $config.ScriptToRun $using:sqlInstance $_.Database $_.SyncObjects $config | Write-Msg
        } catch {
            $errorStr = Get-Error $_ | Out-String
            $errorMsg = $_.Exception.Message
            Write-Msg "Error: ${errorMsg} ${errorStr}"
            # throw # throwing here will cause the parallel loop to stop, so we need to catch, log and continue
        }

        if ($config.VerboseLog) { Write-Msg "Done: Database [$($sw_db.Elapsed)]" }

    } -ThrottleLimit $config.DatabaseConcurrencyLimit

    if ($config.VerboseLog) { Write-Output "[${sqlInstance}] Done: Instance [$($sw_inst.Elapsed)]" }

} -ThrottleLimit $config.InstanceConcurrencyLimit *>&1 | Write-Log

Clear-DbaConnectionPool

<# TODO:
    (ForEach-Object -Parallel) -TimeoutSeconds is terminating, which is fine, but we only want it to terminate the
    Foreach-Object -Parallel loop, not the entire script. If we change the -ErrorAction preference to continue on
    error, then it will also continue on all other exceptions. So we need to add a try/catch to only catch timeout
    errors and continue, otherwise throw.

    Looking at the error that is thrown, it does not include any information to indicate it stopped due to a timeout

    Issue has been submitted to PowerShell:
    https://github.com/PowerShell/PowerShell/issues/19255
#>

#################################################
# Done
#################################################

Write-Log "Done [$($sw.Elapsed)]"
Write-Log '-------------------------------------------------'

#################################################
