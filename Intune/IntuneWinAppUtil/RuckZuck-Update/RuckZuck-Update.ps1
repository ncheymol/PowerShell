param (
    [string]$Package
    )
    Start-Transcript -Path "${env:temp}\Intune-$Package-Update.log"

    Find-Package -Contains $Package -Updates -ErrorAction Stop -verbose | Install-Package -Verbose -ErrorAction Stop
