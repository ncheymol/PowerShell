$result = (Get-Process -Name WWAHost -ErrorAction SilentlyContinue) -ne $null
if ($result -eq $false) {
    Write-Output 1
    Exit 0 
}