
    [string]$Package = "Firefox"


    ($null -ne (Find-Package -Contains $Package -Updates -ErrorAction Stop))