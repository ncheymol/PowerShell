$package = "Microsoft.VisualStudioCode"


$list = winget list --id $package --accept-source-agreements
$exit = $LASTEXITCODE

if ($exit -ne "-1978335212")
    {
    Start-Transcript -Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Winget-$package-detect.ps1.log" -Append
    Write-Host $list
    Stop-Transcript    
    }

#exit $exit