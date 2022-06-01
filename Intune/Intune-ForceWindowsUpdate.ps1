Start-Transcript -Path "c:\ProgramData\Microsoft\IntuneManagementExtension\Logs\force-windowsupdate.log"
if ((Get-PackageProvider | where Name -EQ Nuget) -eq $null)
    {
    Install-PackageProvider -Name NuGet -Force -verbose
    timeout 10
    }

if ((Get-Module -Name PSWindowsUpdate) -eq $null)
    {
    Install-Module -Name PSWindowsUpdate -Force -verbose
    timeout 10
    }

Import-Module PSWindowsUpdate
Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot -verbose
Write-host $LASTEXITCODE
stop-transcript