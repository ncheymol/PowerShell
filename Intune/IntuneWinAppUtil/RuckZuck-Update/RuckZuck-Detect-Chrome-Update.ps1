
    [string]$Package = "Ransack"
    [string]$version = "8.5.2941.1"


    if ($null -ne (Find-Package -Contains $Package -Updates -MaximumVersion $version -ErrorAction Stop))
        {
            Write-Host "Update"
        }
        