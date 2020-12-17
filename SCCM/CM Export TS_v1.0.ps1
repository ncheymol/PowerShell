#Author : Nicolas CHEYMOL
#Date : 04/2014
#Source : https://github.com/ncheymol

$name = Read-Host "enter the TS name to export"

# Site configuration
$SiteCode = "" # Site code 
$ProviderMachineName = "" # SMS Provider machine name

if (!$SiteCode) 
{
$SiteCode = Read-Host "Enter SiteCode"    
}
if (!$ProviderMachineName) 
{
$ProviderMachineName = Read-Host "Enter Primary site servername"    
}

# Customizations
$initParams = @{}
#$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
#$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

# Do not change anything below this line

# Import the ConfigurationManager.psd1 module 
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" @initParams

$TSs = Get-CMTaskSequence -Name $name
foreach ($TS in $TSs)
{
$TSName = $TS.Name
$TS.Name
mkdir -Name ExportTS -Force -Path $env:USERPROFILE
$Path1 = "$env:USERPROFILE\ExportTS\Light\$TSName.zip"
$Path2 = "$env:USERPROFILE\ExportTS\Full\$TSName.zip"
Export-CMTaskSequence -ExportFilePath $path1 -Name $TSName -WithContent $False -WithDependence $false
Export-CMTaskSequence -ExportFilePath $path2 -Name $TSName -WithContent $False -WithDependence $true
}
