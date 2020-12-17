#Author : Nicolas CHEYMOL
#Date : 12/2019
#Source : https://github.com/ncheymol

#region remove accounts
$userprofiles = Get-ChildItem -Path C:\Users | Where-Object name -NE "Public"
foreach ($userprofile in $userprofiles)
    {
    $path = "C:\Users\$($userprofile.Name)\Appdata\Local\Packages"
    $path
    $olds = Get-ChildItem -Path $path | Where-Object Name -Like "*.old"
        foreach ($old in $olds)
        {
        Remove-Item -Path "$path\$old" -Recurse -force
        }

    
    
    $folders = Get-ChildItem -Path $path | Where-Object Name -Like "Microsoft.AAD.BrokerPlugin_*"
    foreach ($folder in $folders)
        {
        Rename-Item -Path "$path\$folder" -NewName "$($folder).old"
        }
    $folders = Get-ChildItem -Path $path | Where-Object Name -Like "Microsoft.Windows.CloudExperienceHost_*"
    foreach ($folder in $folders)
        {
        Rename-Item -Path "$path\$folder" -NewName "$($folder).old"
        }

    }
#endregion
