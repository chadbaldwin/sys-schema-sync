#Requires -PSEdition Core -Version 7.0 -Modules @{ ModuleName="dbatools"; ModuleVersion="2.1.7" }

$env:DBATOOLS_DISABLE_TEPP = $true
$env:DBATOOLS_DISABLE_LOGGING = $true

Import-Module -Name dbatools

$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Invoke-DbaQuery:EnableException'] = $true

$current_path = [string]::IsNullOrWhiteSpace($PSScriptRoot) ? $PWD.Path : $PSScriptRoot

# Get dependencies
$config            = Get-Content -LiteralPath "${current_path}\appsettings.jsonc" -Raw | ConvertFrom-Json
$target_dbs_script = Get-Item -LiteralPath "${current_path}\target_databases.sql"
$script_to_run     = Get-Item -LiteralPath "${current_path}\dependencies\sync_objects.ps1"

# Progress bar style - 'Classic' = always on top, larger; 'Minimal' = inline with output, smaller;
#$PSStyle.Progress.View = 'Classic'

$InstanceConcurrencyLimit = $config.InstanceConcurrencyLimit ?? 5
$DatabaseConcurrencyLimit = $config.DatabaseConcurrencyLimit ?? 1

$logdir = mkdir "${current_path}\$($config.LogDirectory)" -Force

#################################################
# Log cleanup
#################################################

Get-ChildItem -Path $logdir -Filter '*.log' -File |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-($config.LogRetentionDays ?? 30)) } |
    Remove-Item -Force -ErrorAction SilentlyContinue

#################################################
# Helper functions
#################################################

. "${current_path}\shared.ps1"
$PSDefaultParameterValues['Write-Log:LogDirectory'] = $logdir

#################################################
# Starting
#################################################

Write-Log '-------------------------------------------------'
Write-Log 'Starting...'
Write-Log "Concurrent instance throttle limit: ${InstanceConcurrencyLimit}"
Write-Log "Concurrent database throttle limit: ${DatabaseConcurrencyLimit}"
$sw = [Diagnostics.Stopwatch]::StartNew()

#################################################
# Get targets
#################################################

Write-Log 'Establishing connection to database'
try {
    $conn = Connect-DbaInstance -ConnectionString $config.RepositoryDatabaseConnectionString
} catch {
    Write-Log "[ERROR] Failed to connect to database. Exception: $(Get-Error $_ | Out-String)"
    throw
}

Write-Log 'Getting list of instances and databases to run against'
try {
    $targets = Invoke-DbaQuery -SqlInstance $conn -File $target_dbs_script -ReadOnly -As PSObject -QueryTimeout 30 |
        Group-Object Instance | Sort-Object Count -Descending
} catch {
    Write-Log "[ERROR] Failed to get list of instances and databases to run against. Exception: $(Get-Error $_ | Out-String)"
    throw
}

if ($targets.Count -eq 0) {
    Write-Log 'No databases found to run against'
    Write-Log 'Done'
    Write-Log '-------------------------------------------------'
    return
}

Write-Log "Total instances: $($targets.Count)"
Write-Log "Total databases: $($targets.Group.Count)"

#################################################
# Main
#################################################

Write-Log "Total sync tasks: $(($targets.Group.SyncTaskCount | Measure-Object -Sum).Sum)"

# Create a thread-safe dictionary containing each DB
# Used for displaying progress bar and recording progress
$sync = [Collections.Hashtable]::Synchronized(@{})
$targets.Group | ForEach-Object {
    $key = "[$($_.Instance)].[$($_.Database)]"
    $sync[$key] = @{
        Instance = $_.Instance
        Database = $_.Database
        Completed = $false
        ExecutionTime = $null
        Error = $null
    }
}

Write-Log 'Starting concurrent process against instances'
# Handles running instances in parallel
$targets | ForEach-Object -Parallel {
    $sqlInstance = $_.Name
    $syncCopy = $using:sync
    $script_to_run = $using:script_to_run
    $DatabaseConcurrencyLimit = $using:DatabaseConcurrencyLimit

    Write-Output "[${sqlInstance}] Starting Instance, DB Count: $($_.Group.Count)"
    # Handles running databases in parallel
    $_.Group | ForEach-Object -Parallel {
        $db = $_
        $sqlInstance = $using:sqlInstance
        $sqlDatabase = $db.Database
        $syncCopy = $using:syncCopy
        $script_to_run = $using:script_to_run

        $key = "[${sqlInstance}].[${sqlDatabase}]"

        function Write-Msg {
            param ([Parameter(Position=0,ValueFromPipeline)][object]$Message)
            process { Write-Output "${key} ${Message}" }
        }

        Write-Msg "Starting..."

        $sw_db = [Diagnostics.Stopwatch]::StartNew()
        try {
            & $script_to_run -SqlInstance $sqlInstance -SqlDatabase $sqlDatabase | Write-Msg
        } catch {
            Write-Msg "Exception: $(Get-Error $_ | Out-String)"
            # throw # throwing here will cause the parallel loop to stop, so we need to catch, log and continue
        }
        $sw_db.Stop()

        # Update tracker dictionary
        $syncCopy[$key].Completed = $true
        $syncCopy[$key].ExecutionTime = $sw_db.Elapsed
        Write-Msg "Done - [$($syncCopy[$key].ExecutionTime)]"

        # Write progress bar
        $completed_count  = ($syncCopy.Values | Where-Object Completed -eq $true).Count
        $total_count      = $syncCopy.Count
        $pct              = [int]([math]::Floor(($completed_count / $total_count) * 100))
        $progress_message = "${pct}% Completed (${completed_count}/${total_count});"
        Write-Progress -Activity 'Scanning databases' -Status $progress_message -PercentComplete ($pct -gt 100 ? 100 : $pct) # -Completed:($pct -eq 100)
    } -ThrottleLimit $DatabaseConcurrencyLimit
} -ThrottleLimit $InstanceConcurrencyLimit *>&1 | Write-Log

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

$sw.Stop()
Write-Log "Total time to run: $($sw.Elapsed.ToString('hh\:mm\:ss'))"
Write-Log 'Done'
Write-Log '-------------------------------------------------'

#################################################
