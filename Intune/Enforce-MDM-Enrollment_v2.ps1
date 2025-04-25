cmd /c reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\MDM /v AutoEnrollMDM /t REG_DWORD /d 1 /f
cmd /c reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\MDM /v UseAADCredentialType /t REG_DWORD /d 2 /f
cmd /c reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\WorkplaceJoin /v autoWorkplaceKJoin /t REG_DWORD /d 1 /f