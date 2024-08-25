#Requires -PSEdition Core -Version 7.0 -Modules @{ ModuleName="dbatools"; ModuleVersion="2.1.7" }

[CmdletBinding()]
param (
    [Parameter(Mandatory,Position=0)]
    [ValidateScript({Test-Path -Path $_ -PathType Leaf}, ErrorMessage = 'DacPac file not found')]
    [string]$DacPacPath
)

$configPath = Resolve-Path -LiteralPath "${PSScriptRoot}\appsettings.jsonc"

$dacpac = @{
    Path = $DacPacPath
    DacOption = New-DbaDacOption -Type Dacpac -Action Publish
}
$dacpac.DacOption.DeployOptions.AllowIncompatiblePlatform = $true

$config = Get-Content -LiteralPath $configPath -Raw  | ConvertFrom-Json

# Using connectionstring builder to extract the repository database name
$connstr = New-DbaConnectionStringBuilder -ConnectionString $config.RepositoryDatabaseConnectionString
$database = $connstr.Database

# Publish DACPAC
Publish-DbaDacPackage -ConnectionString $config.RepositoryDatabaseConnectionString -Database $database @dacpac
