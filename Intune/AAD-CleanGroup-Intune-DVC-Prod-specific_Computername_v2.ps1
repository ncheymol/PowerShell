$date = get-date -Format yyyyMMdd
$GroupName = "Intune-DVC-Prod"

$log = "$env:TEMP\AAD-CleanGroup-Intune-DVC-Prod-specific_Computername.log"
Start-Transcript $log

# get user UPN
$username = Gwmi -Class Win32_ComputerSystem | select username
$objuser = New-Object System.Security.Principal.NTAccount($username.username)
$sid = $objuser.Translate([System.Security.Principal.SecurityIdentifier])
$upn = Get-ItemPropertyValue -path HKLM:\SOFTWARE\Microsoft\IdentityStore\Cache\$($sid.value)\IdentityCache\$($sid.value) -Name “UserName”

$confirmupn = Read-Host "Do you want to connect with $upn (Y/N) ?"
if ($confirmupn -NE "Y")
    {
    Exit 0
    }

# Connect AAD
Connect-AzureAD -AccountId $upn

#Create group
$existgroups = Get-AzureADGroup -SearchString $GroupName
$existgroups.DisplayName

$Computername = Read-Host "Which computer do you want to remove from the groups ?"

$i = 0
foreach ($group in $existgroups)
    {
    $i++
    write-host "#######################" $i " " $group.DisplayName "#######################"

    $members = Get-AzureADGroupMember -ObjectId $group.ObjectId -All $true | select *
    write-host "group member count : "$members.count
    $removemembers = $members| where DisplayName -EQ $Computername
    $removemembers.count
    $j = 0

    foreach ($member in $removemembers)
        {
        Remove-AzureADGroupMember -MemberId $member.ObjectId -ObjectId $group.ObjectId -Verbose
        write-host $j " " $member.DisplayName
        $j++
        }
    write-host ""
    write-host $i " removed $j devices from" $group.DisplayName
    }


stop-transcript
pause

