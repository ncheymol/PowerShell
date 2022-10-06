<#Install : 
powershell.exe -WindowStyle Hidden -executionpolicy bypass .\Intune-Winget-App_v0.2.ps1 Install <pkgId> -NonInteractive

#Uninstall : 
powershell.exe -WindowStyle Hidden -executionpolicy bypass .\Intune-Winget-App_v0.2.ps1 Uninstall <pkgId> -NonInteractive
#>

param (
    [string]$Action,
    [string]$WingetPackages
    )

Start-Transcript -Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Winget-$WingetPackages-install.ps1.log"


if ($Action -eq "install")
    {
    foreach($Package in $WingetPackages) 
        {
         try 
            {
			write-host "************************** Install **************************"
            $install = winget install --id $package -h --accept-package-agreements --accept-source-agreements
            $install
            }
         catch 
            {
             Throw “Failed to $Action $Package”
            }
         }
    }

if ($Action -eq "Uninstall")
    {
    foreach($Package in $ChocoPackages) 
        {
         try 
            {
            write-host "************************** Uninstall **************************"
            $install = winget uninstall --id $package -h --accept-package-agreements --accept-source-agreements
            }
         catch 
            {
            Throw “Failed to $Action $Package”
            }
        }

    }

stop-transcript