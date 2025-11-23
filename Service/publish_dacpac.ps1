#Requires -PSEdition Core -Version 7.0 -Modules @{ ModuleName="dbatools"; ModuleVersion="2.1.7" }

$ErrorActionPreference = 'Stop'

$config = Get-Content -LiteralPath "${PSScriptRoot}\appsettings.jsonc" -Raw | ConvertFrom-Json
$dacPacPath = Get-Item -LiteralPath "${PSScriptRoot}\SysSchemaSync.dacpac"

$dacpac = @{
    Path = $dacPacPath
    DacOption = New-DbaDacOption -Type Dacpac -Action Publish
}
$dacpac.DacOption.DeployOptions.AllowIncompatiblePlatform = $true

# Using connectionstring builder to extract the repository database name
$connstr = New-DbaConnectionStringBuilder -ConnectionString $config.RepositoryDatabaseConnectionString
$database = $connstr.Database

# Publish DACPAC
Publish-DbaDacPackage -ConnectionString $config.RepositoryDatabaseConnectionString -Database $database @dacpac -Verbose
