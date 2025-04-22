$domain = Read-Host "domain"
$id = Read-Host "username"
$oldpassword = Read-Host "old password"
$newpassword = Read-Host "new password"
([adsi]"WinNT://$($domain)/$($id),user").ChangePassword("$($oldpassword)","$($newpassword)")
