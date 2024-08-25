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
        $msg = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ${logLevel} ${Message}"
        if ($LogDirectory) { $msg | Add-Content (Join-Path $LogDirectory "$(Get-Date -Format 'yyyy-MM-dd').log") }
        $msg | Write-Host
    }
}

function ConvertFrom-DBNull {
    param ([Parameter(Position=0,ValueFromPipeline=$true)][object]$value)
    process { $value -is [DBNull] ? $null : $value }
}
