<#
.SYNOPSIS
    This script is provided As Is with no support. You can contact me on github or linkedin if you have any question or remark.

.DESCRIPTION
	Proactive remediation to install application update with winget

.PARAMETER Type

.NOTES
    Version: 1.0
    Author: Nicolas CHEYMOL
    Created: 22/07/2022
    Updated: 

.HISTORY 
    1.0 - Script created

.LINK 
    https://github.com/ncheymol

.COPYRIGHT
Copyright (c) Nicolas CHEYMOL. All rights reserved.

#>

$date = Get-Date -Format yyyyMMdd
Start-Transcript -Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\VLC_Update_Remediate.log"
$package = "VideoLAN.VLC"
#set process value to "" if you want to skip process check
$process = "vlc"

# Obtain  
$upgradable = winget upgrade | select-string $package
$exit = $LASTEXITCODE
Write-Output $upgradable

# Check for returned values, if null, write output and exit 1
if ($upgradable -eq $null) 
    {
    Stop-Transcript
    Write-Output "$upgradable | OK : $(Get-Date) "
    Exit 0
    }
else 
    {
    if ($process -ne "")
        {
        #check if the application is running
        $procstat = get-process | where ProcessName -contains $process
        if ($procstat -ne $null)
            {
            Write-Output "$($procstat.Id) | $($procstat.ProcessName) | Running : $(Get-Date) "
            Stop-Transcript
            Write-Output "$($procstat.Id) | $($procstat.ProcessName) | Running : $(Get-Date) "
            Exit 1
            }
        }
    # upgrade application
    winget upgrade --id $package
    $exit = $LASTEXITCODE

    #Report update status  
    $list = winget list $package
    Write-Output "$list | OK : $(Get-Date) "
	Stop-Transcript
    Write-Output "$list | OK : $(Get-Date) "
    Exit $exit
    }






