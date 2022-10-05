# Intune Powershell Scripts

Script descritions :

  Intune-Backup-static.ps1 : Backup All Intune in D:\temp\IntuneBackup (uses John Seerden's modules, https://www.srdn.io/2019/03/backup-and-restore-your-microsoft-intune-configuration-with-powershell/)
  
  Intune-Backup.ps1 : Backup All Intune in a prompted location (uses John Seerden's modules, https://www.srdn.io/2019/03/backup-and-restore-your-microsoft-intune-configuration-with-powershell/)
    
  Intune-CompareBackup.ps1 : Compares two full Backups, folder locations are prompted (uses John Seerden's modules, https://www.srdn.io/2019/03/backup-and-restore-your-microsoft-intune-configuration-with-powershell/)

  Intune-LAPS-Detection.ps1 : allows to detect the age of the local admin password. This script should be used as a detection rule in Intune for the LAPS script 
  
  New-LocalAdmin.ps1 after packaging it as an IntuneWin32 app. : https://www.srdn.io/2018/09/serverless-laps-powered-by-microsoft-intune-azure-functions-and-azure-key-vault/

  IntuneWinAppUtil : a bunch of scripts to easily package Win32 apps in Intune
  
  Proactive Remediation : the scripts I use in proactive remediation to manage computers 
  
  Bitlocker-backupkey.ps1 : Force Windows 10 to save its Bitlocker recovery key in Azure AD

  PowerCFG-Autopilot.ps1 : Set High Perf and disable Sleep during Autopilot
