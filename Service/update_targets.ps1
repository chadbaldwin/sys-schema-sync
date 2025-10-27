#Requires -PSEdition Core -Version 7.0 -Modules @{ ModuleName="dbatools"; ModuleVersion="2.1.7" }

$config = gc "${PSScriptRoot}\appsettings.jsonc" -Raw | ConvertFrom-Json
$targets = gc "${PSScriptRoot}\targets.json" -Raw

$conn = Connect-DbaInstance -ConnectionString $config.RepositoryDatabaseConnectionString

$params = @{
    SqlInstance = $conn
    CommandType = 'StoredProcedure'
    Query = 'import.usp_UpdateTargets'
    SqlParameter = @{ 'ServiceConfigJSON' = $targets }
}
$result = Invoke-DbaQuery @params -As DataSet

$result.Tables[0] | Format-Table -AutoSize
$result.Tables[1] | Format-Table -AutoSize