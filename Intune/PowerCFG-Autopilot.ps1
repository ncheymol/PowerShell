Start-Transcript -Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\PowerCFG-Autopilot.log" -Append

$result = (Get-Process -Name WWAHost -ErrorAction SilentlyContinue) -ne $null
if ($result -eq $false) 
    {
   $Provisioning = Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Provisioning
   if ($Provisioning.FirstRunComplete -eq 1)
        {
        Write-Host "Restore Defaults"
        PowerCfg.exe -restoredefaultschemes
        stop-transcript
        Exit 0 
        }
    }
else
    {
    PowerCfg.exe /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 0
    PowerCfg.exe /X monitor-timeout-ac 0
    PowerCfg.exe /X monitor-timeout-dc 0
    PowerCfg.exe /X standby-timeout-ac 0
    PowerCfg.exe /X standby-timeout-dc 0
    PowerCfg.exe /X hibernate-timeout-ac 0
    PowerCfg.exe /X hibernate-timeout-dc 0
    stop-transcript
    Exit 1
    }

Write-Host "Neither"

stop-transcript
Exit 1