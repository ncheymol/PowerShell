param (
    [string]$Action,
    [string]$ChocoPackages
    )

Start-Transcript -Path "${env:temp}\Intune-$ChocoPackages-$Action.log"


$ChocoInstall = Join-Path ([System.Environment]::GetFolderPath(“CommonApplicationData”)) “Chocolatey\bin\choco.exe”

if(!(Test-Path $ChocoInstall)) {
     try {

         Invoke-Expression ((New-Object net.webclient).DownloadString(‘https://chocolatey.org/install.ps1’)) -ErrorAction Stop
     }
     catch {
         Throw “Failed to install Chocolatey”
     }       
}

if ($Action -eq "install")
    {
    foreach($Package in $ChocoPackages) 
        {
         try 
            {
             $install = Invoke-Expression “cmd.exe /c $ChocoInstall Install $Package -y --ignorechecksum” -ErrorAction Stop
             $install
             $isinstalled = $install | Select-String "already installed."
                if ($null -ne $isinstalled)
                    {
                    Invoke-Expression “$ChocoInstall Upgrade $Package -y --ignorechecksum” -ErrorAction Stop
                    $upgrade
                    }
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
            Invoke-Expression “cmd.exe /c $ChocoInstall UnInstall $Package -y --ignorechecksum” -ErrorAction Stop
            }
         catch 
            {
            Throw “Failed to $Action $Package”
            }
        }

    }

stop-transcript