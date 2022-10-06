$1 = Get-ChildItem -Path HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Capture
$5 = $null
foreach ($2 in $1)
    {
    $3 = Get-ItemProperty -path "$($2.PSPath)\Properties" 
    $4 = $3.psobject.Properties | Where-Object { $_.Value -like "*Jabra*" }
    if ($4.value -ne $null)
        {
        $5 += "$($4.value) ," 
        }
    }
    $result = $5 -ne $null
    write-output $result