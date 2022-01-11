param (
    [string]$Action
    )


$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked"
$registryPath2 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked"

$Name = "{e2bf9676-5f8f-435c-97eb-11607a5bedf7}"
$value = ""

if ($Action -eq "Install")
{
IF(!(Test-Path $registryPath))
    {
    New-Item -Path $registryPath -Force | Out-Null
    New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType STRING -Force | Out-Null
    }
    ELSE 
    {
    New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType STRING -Force | Out-Null
    }


IF(!(Test-Path $registryPath2))
    {
    New-Item -Path $registryPath2 -Force | Out-Null
    New-ItemProperty -Path $registryPath2 -Name $name -Value $value -PropertyType STRING -Force | Out-Null
    }
    ELSE 
    {
    New-ItemProperty -Path $registryPath2 -Name $name -Value $value -PropertyType STRING -Force | Out-Null
    }
    Stop-Process -Name Explorer
    Start-Process -FilePath explorer
}


if ($Action -eq "Uninstall")
{
Remove-ItemProperty -Name $name -Path $registryPath
Remove-ItemProperty -Name $name -Path $registryPath2
}

Exit 3010