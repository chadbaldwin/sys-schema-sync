#Requires -PSEdition Core -Version 7.2 -Modules @{ ModuleName="dbatools"; ModuleVersion="2.1.7" }

$env:DBATOOLS_DISABLE_TEPP = $true
$env:DBATOOLS_DISABLE_LOGGING = $true
Import-Module -Name dbatools
$PSDefaultParameterValues['Invoke-DbaQuery:EnableException'] = $true

$ErrorActionPreference = 'Stop'

$current_path = [string]::IsNullOrWhiteSpace($PSScriptRoot) ? $PWD.Path : $PSScriptRoot

# Get dependencies
$config = Get-Content -LiteralPath "${current_path}\appsettings.jsonc" -Raw | ConvertFrom-Json -AsHashtable

$config.InstanceConcurrencyLimit = $config.InstanceConcurrencyLimit ?? 5
$config.DatabaseConcurrencyLimit = $config.DatabaseConcurrencyLimit ?? 1
$config.ScriptToRun = Get-Item -LiteralPath "${current_path}\dependencies\sync_objects.ps1"

$logdir = mkdir "${current_path}\$($config.LogDirectory)" -Force

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
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-($config.LogRetentionDays ?? 30)) } |
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
    $targets = Invoke-DbaQuery -SqlInstance $conn -Query $query_target -As PSObject -QueryTimeout 30 |
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
    $config = $using:config
    $sqlInstance = $_.Instance
    $sw_inst = [Diagnostics.Stopwatch]::StartNew()
    Write-Output "[${sqlInstance}] Start: Instance [DBCount: $($_.Databases.Count)]"
    # Handles running databases in parallel
    $_.Databases | ForEach-Object -Parallel {
        $config = $using:config
        $key = "[{0}].[{1}]" -f $using:sqlInstance, $_.Database
        function Write-Msg {
            param ([Parameter(Position=0,ValueFromPipeline)][object]$Message)
            process { Write-Output "${key} ${Message}" }
        }

        Write-Msg "Start: Database"
        $sw_db = [Diagnostics.Stopwatch]::StartNew()
        try {
            & $config.ScriptToRun -SqlInstance $using:sqlInstance -SqlDatabase $_.Database -SyncObjects $_.SyncObjects -Config $config | Write-Msg
        } catch {
            Write-Msg "Exception: $(Get-Error $_ | Out-String)"
            # throw # throwing here will cause the parallel loop to stop, so we need to catch, log and continue
        }
        $sw_db.Stop()

        Write-Msg "Done: Database [$($sw_db.Elapsed)]"
    } -ThrottleLimit $config.DatabaseConcurrencyLimit
    Write-Output "[${sqlInstance}] Done: Instance [$($sw_inst.Elapsed)]"
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

$sw.Stop()
Write-Log "Total time to run: $($sw.Elapsed.ToString('hh\:mm\:ss'))"
Write-Log 'Done'
Write-Log '-------------------------------------------------'

#################################################
