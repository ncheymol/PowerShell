<#
.SYNOPSIS
    This script is provided As Is with no support. You can contact me on github or linkedin if you have any question or remark.

.DESCRIPTION
	Proactive remediation to detect application update with winget

.PARAMETER Type

.NOTES
    Version: 1.0
    Author: Nicolas CHEYMOL
    Website : https://github.com/ncheymol
    Created: 22/07/2022
    Updated: 

.HISTORY 
    1.0 - Script created

.LINK 

.COPYRIGHT
Copyright (c) Nicolas CHEYMOL. All rights reserved.

#>


$date = Get-Date -Format yyyyMMdd
Start-Transcript -Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\VLC_Update_Detect.log"
#Winget Package ID : Winget search VLC
$package = "VideoLAN.VLC"

# Check a specific version is installed (VLC 3.0.17.4 is detected as 3.0.17.0)  
$list = winget list --accept-source-agreements | select-string "$package" | select-string "3.0.17.0"

#Check if an upgrade is available for the specified Package
$upgradable = winget upgrade | select-string $package
$exit = $LASTEXITCODE
Write-Output $upgradable

# Check for returned values, if null, write output and exit 1
if (($upgradable -eq $null) -or ($list -ne $null) )
    {
    Stop-Transcript
    if ($exit -ne "-1978335212")
    {
    Write-Output "OK : $(Get-Date) "
    }
    else
        {
        Write-Output "NotInstalled : $(Get-Date) "
        }   
        Exit 0
    }
else 
    {
	Stop-Transcript
    Write-Output "$upgradable | NOK : $(Get-Date) "
    Exit 1
    }






