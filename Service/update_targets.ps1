#Requires -PSEdition Core -Version 7.0 -Modules @{ ModuleName="dbatools"; ModuleVersion="2.1.7" }

[CmdletBinding()]
param ()

$ErrorActionPreference = 'Stop'

$config = Get-Content -LiteralPath "${PSScriptRoot}\appsettings.jsonc" -Raw | ConvertFrom-Json
$targets = Get-Content -LiteralPath "${PSScriptRoot}\targets.json" -Raw

Write-Host 'Establishing connection with repository database...'
$conn = Connect-DbaInstance -ConnectionString $config.RepositoryDatabaseConnectionString -ConnectTimeout 10

Write-Host 'Updating targets'
$params = @{
    SqlInstance = $conn
    CommandType = 'StoredProcedure'
    Query = 'import.usp_UpdateTargets'
    SqlParameter = @{ ServiceConfigJSON = $targets; Verbose = $true }
    As = 'DataSet'
    QueryTimeout = 10
    EnableException = $true
}
$result = Invoke-DbaQuery @params -Verbose

$result.Tables[0] | Format-Table -AutoSize
$result.Tables[1] | Format-Table -AutoSize