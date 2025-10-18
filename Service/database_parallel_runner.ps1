#Requires -PSEdition Core -Version 7.0 -Modules @{ ModuleName="dbatools"; ModuleVersion="2.1.7" }

$env:DBATOOLS_DISABLE_TEPP = $true
$env:DBATOOLS_DISABLE_LOGGING = $true

Import-Module -Name dbatools

$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Invoke-DbaQuery:EnableException'] = $true

$current_path = [string]::IsNullOrWhiteSpace($PSScriptRoot) ? $PWD.Path : $PSScriptRoot

# Get dependencies
$config        = Get-Content -LiteralPath "${current_path}\appsettings.jsonc" -Raw | ConvertFrom-Json
$script_to_run = Get-Item -LiteralPath "${current_path}\dependencies\sync_objects.ps1"

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
$query_target = @'
    -- Throwing in some sql injection protection - still need to figure out how to handle the ChecksumQueryText
    SELECT _InstanceID, _DatabaseID, InstanceName, DatabaseName
        , SyncObjectID, SyncObjectName, SyncObjectLevelID, LastSyncChecksum
        , SyncObjectNameClean = NULLIF(CONCAT_WS('.', QUOTENAME(PARSENAME(q.SyncObjectName, 3)), QUOTENAME(PARSENAME(q.SyncObjectName, 2)), QUOTENAME(PARSENAME(q.SyncObjectName, 1))), '')
        , ImportTableClean    = NULLIF(CONCAT_WS('.', QUOTENAME(PARSENAME(q.ImportTable   , 3)), QUOTENAME(PARSENAME(q.ImportTable   , 2)), QUOTENAME(PARSENAME(q.ImportTable   , 1))), '')
        , ImportProcClean     = NULLIF(CONCAT_WS('.', QUOTENAME(PARSENAME(q.ImportProc    , 3)), QUOTENAME(PARSENAME(q.ImportProc    , 2)), QUOTENAME(PARSENAME(q.ImportProc    , 1))), '')
        , ImportTypeClean     = NULLIF(CONCAT_WS('.', QUOTENAME(PARSENAME(q.ImportType    , 3)), QUOTENAME(PARSENAME(q.ImportType    , 2)), QUOTENAME(PARSENAME(q.ImportType    , 1))), '')
        , ExportQueryPath, ChecksumQueryText
    FROM import.vw_DatabaseSyncObjectQueue q;
'@
try {
    $targets = Invoke-DbaQuery -SqlInstance $conn -Query $query_target -ReadOnly -As PSObject -QueryTimeout 30 |
        Group-Object InstanceName |
        ForEach-Object {
            $databases = $_.Group |
                Group-Object DatabaseName |
                ForEach-Object {
                    [pscustomobject]@{
                        Database = $_.Name
                        SyncObjects = $_.Group
                    }
                }

            [pscustomobject]@{
                Instance = $_.Name
                Databases = $databases
            }
        }
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
Write-Log "Total databases: $($targets.Databases.Count)"
Write-Log "Total sync tasks: $($targets.Databases.SyncObjects.Count)"

#################################################
# Main
#################################################

Write-Log 'Starting concurrent process against instances'
# Handles running instances in parallel
$targets | ForEach-Object -Parallel {
    $databases = $_.Databases
    $sqlInstance = $_.Instance
    $script_to_run = $using:script_to_run
    $DatabaseConcurrencyLimit = $using:DatabaseConcurrencyLimit

    Write-Output "[${sqlInstance}] Starting Instance, DB Count: $($databases.Count)"
    # Handles running databases in parallel
    $databases | ForEach-Object -Parallel {
        $syncObjects = $_.SyncObjects
        $sqlInstance = $using:sqlInstance
        $sqlDatabase = $_.Database
        $script_to_run = $using:script_to_run
        $key = "[${sqlInstance}].[${sqlDatabase}]"

        function Write-Msg {
            param ([Parameter(Position=0,ValueFromPipeline)][object]$Message)
            process { Write-Output "${key} ${Message}" }
        }

        Write-Msg "Starting..."
        $sw_db = [Diagnostics.Stopwatch]::StartNew()
        try {
            & $script_to_run -SqlInstance $sqlInstance -SqlDatabase $sqlDatabase -SyncObjects $syncObjects | Write-Msg
        } catch {
            Write-Msg "Exception: $(Get-Error $_ | Out-String)"
            # throw # throwing here will cause the parallel loop to stop, so we need to catch, log and continue
        }
        $sw_db.Stop()

        Write-Msg "Done - [$($sw_db.Elapsed)]"
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
