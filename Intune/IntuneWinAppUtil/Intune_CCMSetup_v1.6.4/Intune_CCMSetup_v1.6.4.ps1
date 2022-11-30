Param (
[parameter(Mandatory=$false)]
$trigger = "{00000000-0000-0000-0000-000000000021}",
$machine = $env:COMPUTERNAME
)

Start-Transcript -Path "C:\Windows\Logs\CcmSetup.msi.ps1.log"
Write-Host (Get-Date)
#region Install
Stop-Process -Name PanGPS -force -Verbose
timeout 10
Start-Process msiexec -Wait -ArgumentList '/i ccmsetup.msi /q CCMSETUPCMD="CCMHOSTNAME=<CMG Adress> SMSSiteCode=P01 AADTENANTID=<Tenantid> AADCLIENTAPPID=<ClientId> AADRESOURCEURI=https://<App Registration URI> PROVISIONTS=P0120099 /nocrlcheck"' -Verbose
#timeout 10
#Wait-Process -Name ccmsetup
Do {timeout 10} While ((Get-Service -Name ccmsetup -ErrorAction SilentlyContinue) -ne $null)
Write-Host (Get-Date)
timeout 10
#endregion install


#region Parselogs
#Filter the log to get only exit entries
$string = "CcmSetup is exiting with return code "

#Get the log content
$exitlog = get-content "C:\Windows\ccmsetup\Logs\ccmsetup.log" | select-string $string


#Select last entry
#$exitlog = $log.Item(($log.Count)-1)

#split to extract the exit code
$split = (($exitlog -split "]").Item(0)).split(" ")
$ccmsetup_exitcode = $split.item(($split.Count)-1)
#endregion parselogs


#region stopccmexec
# Stop CcmExec to prevent conflict between Intune and SCCM Deployments
Write-Host (Get-Date)
if (($ccmsetup_exitcode -eq "0") -or ($ccmsetup_exitcode -eq "7"))
    {
    stop-Service -Name CcmExec -Verbose
    #move workloads to Intune
    reg add  HKLM\SOFTWARE\Microsoft\CCM /v CoManagementFlags /t REG_QWORD /f /d 255
    $ErrorActionPreference = "SilentlyContinue"
    $arguments = @(
    "-command"
    'Do {timeout 60} While ((Get-Process -Name WWAHost).Responding -eq $true); Start-Service -Name CcmExec -verbose;  Timeout 240; Invoke-WMIMethod -ComputerName $env:computername -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000021}"; timeout 300; Invoke-WMIMethod -ComputerName $env:computername -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000021}"; timeout 300; reg add  HKLM\SOFTWARE\Microsoft\CCM /v CoManagementFlags /t REG_QWORD /f /d 255 >> C:\Windows\Logs\CcmSetup.msi.ps1.log')
    $arguments
    # Restart CCMExec Once the ESP has ended
    $ErrorActionPreference = "Continue"
    Start-Process -FilePath "c:\windows\sysnative\windowspowershell\v1.0\powershell.exe" -ArgumentList $arguments
    }
#endregion stopccmexec
$args = $null

Start-Sleep -Seconds 120

## Connect to Software Center
Try {
Write-Host "$((Get-Date).ToShortTimeString()) - Connecting to the SCCM client Software Center..."
$SoftwareCenter = New-Object -ComObject "UIResource.UIResourceMgr"
}
Catch {
Write-Host "$((Get-Date).ToShortTimeString()) - Failed to connect to Software Center."
exit 1
}

##Initiates trigger of Machine Policy Retrieval and Evaluation
#Write-Host "$((Get-Date).ToShortTimeString()) - Trying to invoke Machine Policy Retrieval..."
#Invoke-WmiMethod -ComputerName $machine -Namespace root\ccm -Class sms_client -Name TriggerSchedule $trigger | Out-Null
#Start-Sleep -Seconds 15
#powershell.exe -executionpolicy bypass -windowstyle hidden ./ForceUpdateConfigMgr.ps1 -PackageID PR100164
#powershell.exe -executionpolicy bypass -windowstyle hidden {start-process powershell -WindowStyle Hidden -ArgumentList ".\ForceUpdateConfigMgr.ps1 -PackageID PR100164"}

Write-Host $ccmsetup_exitcode
Write-Host (Get-Date)
Stop-Transcript

exit $ccmsetup_exitcode