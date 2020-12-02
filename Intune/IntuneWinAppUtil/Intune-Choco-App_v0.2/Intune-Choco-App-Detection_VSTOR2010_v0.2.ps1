$package = "VSTOR2010"

$list = choco list --local-only --exact $package

if (($list | Select-String "packages installed.") -notlike "*0 packages installed.*")
    {
    Write-Host $package
    }
