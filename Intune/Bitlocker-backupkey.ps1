#Author : Nicolas CHEYMOL
#Date : 12/2020
#Source : https://github.com/ncheymol

$letter = "C"
$Volume = Get-BitLockerVolume -MountPoint $letter
$KeyProtector = $Volume.KeyProtector | where KeyProtectorType -EQ RecoveryPassword
$KeyProtectorId = $KeyProtector.KeyProtectorId

Backup-BitLockerKeyProtector -KeyProtectorId $KeyProtectorId -MountPoint $letter
BackupToAAD-BitLockerKeyProtector -KeyProtectorId $KeyProtectorId -MountPoint $letter
