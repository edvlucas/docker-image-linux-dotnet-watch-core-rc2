<#
.SYNOPSIS
Downloads the given $Version of clrdbg for the given $RuntimeID and installs it to the given $InstallPath

.DESCRIPTION
The following script will generate a project.json and NuGet.config and use dotnet restore and publish to install clrdbg, the .NET Core Debugger

.PARAMETER Version
Specifies the version of clrdbg to install. Can be 'latest', VS2015U2, or a specific version string i.e. 14.0.25229-preview-2963841

.PARAMETER RuntimeID
Specifies the .NET Runtime ID of the clrdbg that will be downloaded. Example: ubuntu.14.04-x64. Defaults to the Runtime ID of the current machine.

.Parameter InstallPath
Specifies the path where clrdbg will be installed. Defaults to the directory containing this script.

.INPUTS
None. You cannot pipe inputs to GetClrDbg.

.EXAMPLE
C:\PS> .\GetClrDbg.ps1 -Version latest -RuntimeID ubuntu.14.04-x64 -InstallPath .\clrdbg

.LINK
https://github.com/Microsoft/MIEngine
#>

Param (
    [Parameter(Mandatory=$true, ParameterSetName="ByName")]
    [string]
    [ValidateSet("latest", "VS2015U2")]
    $Version,

    [Parameter(Mandatory=$true, ParameterSetName="ByNumber")]
    [string]
    [ValidatePattern("\d+\.\d+\.\d+.*")]
    $VersionNumber,

    [string]$RuntimeID,
    [string]$InstallPath = (Split-Path -Path $MyInvocation.MyCommand.Definition)
)

function GetDotNetRuntimeID() {
    $ridLine = dotnet --info | findstr "RID"
    
    if ([System.String]::IsNullOrEmpty($ridLine)) {
        throw [System.Exception] "Unable to determine runtime from dotnet --info. Make sure dotnet cli is up to date on this machine"
    }

    $rid = $ridLine.Split(":")[1].Trim();

    if ([System.String]::IsNullOrEmpty($rid)) {
        throw [System.Exception] "Unable to determine runtime from dotnet --info. Make sure dotnet cli is up to date on this machine"
    }

    return $rid
}

# Produces project.json in the current directory
function GenerateProjectJson([string] $version, [string]$runtimeID) {
    $projectJson = 
"{
    `"dependencies`": {
       `"Microsoft.VisualStudio.clrdbg`": `"$version`"
    },
    `"frameworks`": {
        `"netstandardapp1.5`": {
          `"imports`": [ `"dnxcore50`", `"portable-net45+win8`" ]
       }
   },
   `"runtimes`": {
      `"$runtimeID`": {}
   }
}"

    $projectJson | Out-File -Encoding utf8 project.json
}

# Produces NuGet.config in the current directory
function GenerateNuGetConfig() {
    $nugetConfig = 
"<?xml version=`"1.0`" encoding=`"utf-8`"?>
<configuration>
  <packageSources>
      <clear />
      <add key=`"api.nuget.org`" value=`"https://api.nuget.org/v3/index.json`" />
  </packageSources>
</configuration>"

    $nugetConfig | Out-File -Encoding utf8 NuGet.config
}

# Add new version constants here
# 'latest' version may be updated
# all other version constants i.e. 'vs2015u2' may not be updated after they are finalized
if ($Version -eq "latest") {
    $VersionNumber = "14.0.25229-preview-2963841"
} elseif ($Version -eq "vs2015u2") {
    $VersionNumber = "14.0.25229-preview-2963841"
}
Write-Host "Info: Using clrdbg version '$VersionNumber'"

if (-not $RuntimeID) {
    $RuntimeID = GetDotNetRuntimeID
}
Write-Host "Info: Using Runtime ID '$RuntimeID'"

# create the install folder if it does not exist
if (-not (Test-Path -Path $InstallPath -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $InstallPath
}
$InstallPath = Resolve-Path -Path $InstallPath -ErrorAction Stop

Push-Location $InstallPath -ErrorAction Stop

Write-Host "Info: Generating project.json"
GenerateProjectJson $VersionNumber $RuntimeID

Write-Host "Info: Generating NuGet.config"
GenerateNuGetConfig

Write-Host "Info: Executing dotnet restore"
dotnet restore

Write-Host "Info: Executing dotnet publish"
dotnet publish -r $RuntimeID -o $InstallPath

Pop-Location

Write-Host "Successfully installed clrdbg at '$InstallPath'"