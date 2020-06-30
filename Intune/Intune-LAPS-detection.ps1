$username = "LocalAdmin"
$user = Get-LocalUser -Name $username -ErrorAction SilentlyContinue
if ($user -eq $null)
    {
    Write-Host "Not existing"
    Exit 668
    }
Else
    {
    $PasswordLastSet = $user.PasswordLastSet
    if (((Get-Date).AddDays(90) - $PasswordLastSet ) -le 0 )
        {
        Write-Host "Expired"
        Exit 1618
        }
    Else
        {
        Write-Host "OK"
        }
    }
