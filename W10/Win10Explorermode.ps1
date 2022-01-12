param (
    [string]$Action
    )

Start-Transcript -Path "C:\ProgramData\Microsoft\IntuneManagementExtension\logs\Win10Explorermode.ps1.log" -Append

$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked"
$registryPath2 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked"

$Name = "{e2bf9676-5f8f-435c-97eb-11607a5bedf7}"
$value = ""

if ($Action -eq "Install")
{
IF(!(Test-Path $registryPath))
    {
    New-Item -Path $registryPath -Force -Verbose
    New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType STRING -Force -Verbose
    }
ELSE 
    {
    New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType STRING -Force -Verbose
    }


IF(!(Test-Path $registryPath2))
    {
    New-Item -Path $registryPath2 -Force -Verbose
    New-ItemProperty -Path $registryPath2 -Name $name -Value $value -PropertyType STRING -Force  -Verbose
    }
ELSE 
    {
    New-ItemProperty -Path $registryPath2 -Name $name -Value $value -PropertyType STRING -Force  -Verbose
    }
    Stop-Process -Name Explorer -Force -Verbose
    Start-Process -FilePath explorer -Verbose
}


if ($Action -eq "Uninstall")
{
Remove-ItemProperty -Name $name -Path $registryPath -Verbose
Remove-ItemProperty -Name $name -Path $registryPath2 -Verbose
}

Exit 3010
