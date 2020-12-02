Start-Transcript -Path "C:\MININT\SMSOSD\OSDLOGS\9-Disable-BiometryService.log"

# Gestion des codes de sortie
function ExitWithCode
{ 
    param 
    ( 
        $exitcode 
    )
    $host.SetShouldExit($exitcode) 
    exit 
}

$Biometrics = Get-ChildItem C:\Windows\System32\WinBioDatabase | where Name -NE "51F39552-1075-4199-B513-0C10EA185DB0.DAT"

if ($Biometrics -ne $null)
    {
    # désactivation de Windows Biometric Service
    $BioServ = Get-Service | where {$_.Name -eq "WbioSrvc"}

    if ($BioServ.Status -eq "Running") 
        {
            Do 
                {
                Stop-Service $BioServ -Force -Verbose
                $i++
                $i
                timeout 1
                if ($i -gt 30)
                    {
                    $id = Get-WmiObject -Class Win32_Service -Filter "Name LIKE 'WbioSrvc'" | Select-Object -ExpandProperty ProcessId
                    stop-Process -Id $id -Force -Verbose
                    }

                $BioServ = Get-Service | where {$_.Name -eq "WbioSrvc"}
                } While (($BioServ.Status -eq "Running") -and ($i -lt 90))
        Write-Host "Le service Windows Biometric Service est arrêté"
        $exit = 0
        } 
    else 
        {
        Write-Host "Le service Windows Biometric Service est désactivé sur ce poste"
        $exit = 0
        }
    }
else 
    {
    Write-Host "La Biométrie n'est pas configurée sur le poste"
    write-host "Clear Windows Hello (convenience PIN) database"
    certutil -deleteHelloContainer 
    $exit = 0

    }

Write-Output "On sort du script avec le code de sortie $exit"
Stop-Transcript
ExitWithCode $exit