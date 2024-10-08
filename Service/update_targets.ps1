#Requires -PSEdition Core -Version 7.0 -Modules @{ ModuleName="dbatools"; ModuleVersion="2.1.7" }

$config = gc "${PSScriptRoot}\appsettings.jsonc" -Raw  | ConvertFrom-Json

# Converting back to JSON rather than using the source so we can remove comments.
# PowerShell supports comments in JSON, but SQL Server does not
$configJSON = $config | ConvertTo-Json

$conn = Connect-DbaInstance -ConnectionString $config.RepositoryDatabaseConnectionString

$params = @{
    SqlInstance = $conn
    CommandType = 'StoredProcedure'
    Query = 'import.usp_UpdateTargets'
    SqlParameter = @{ 'ServiceConfigJSON' = $configJSON }
}
Invoke-DbaQuery @params
