param (
    [string]$link,
    [string]$cmd,
    [string]$file,
    [string]$arg1,
    [string]$arg2
    )

Start-Transcript -Path "${env:temp}\Intune-$file.log"

Write-Host $link

Set-Location $env:temp
(Get-Location).Path
Write-Host $file

#Invoke-WebRequest -Uri $link -OutFile $file

$exec = ("/c $cmd $arg1 $file $arg2").Replace('  ',' ')

Write-Host $exec

Start-Process -FilePath "cmd" -ArgumentList "$exec" -wait -Verbose -Debug


stop-transcript