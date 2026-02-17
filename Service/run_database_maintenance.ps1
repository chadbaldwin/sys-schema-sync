#Requires -PSEdition Core -Version 7.0 -Modules @{ ModuleName="dbatools"; ModuleVersion="2.1.7" }

$ErrorActionPreference = 'Stop'

$config = Get-Content -LiteralPath "${PSScriptRoot}\appsettings.jsonc" -Raw | ConvertFrom-Json
$targets = Get-Content -LiteralPath "${PSScriptRoot}\targets.json" -Raw

Write-Host 'Establishing connection with repository database...'
$conn = Connect-DbaInstance -ConnectionString $config.RepositoryDatabaseConnectionString -ConnectTimeout 10

Write-Host 'Running Database Maintenance Proc'
$params = @{
    SqlInstance = $conn
    CommandType = 'StoredProcedure'
    Query = 'import.usp_DatabaseMaintenanceTasks'
    SqlParameter = @{ Verbose = $true }
    QueryTimeout = 10
    EnableException = $true
}
Invoke-DbaQuery @params -Verbose