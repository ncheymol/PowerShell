#region Funstions

function Test-Admin 
{ 
#-------------------------------------------------------------------------------
# Function Test-Admin
#
# Returns True if running as admin
#-------------------------------------------------------------------------------
   $currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() ) 
   if ($currentPrincipal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )) 
   { 
      return $true 
   } 
   else 
   { 
      return $false 
   } 
}  

Function Restart-ScriptAsAdmin
{
#-------------------------------------------------------------------------------
# Function Restart-ScriptAsAdmin
#
#
#-------------------------------------------------------------------------------
	$Invocation=((Get-Variable MyInvocation).value).ScriptName 
	
	if ($Invocation -ne $null) 
	{ 
	   $arg="-command `"& '"+$Invocation+"'`"" 
	   if (!(Test-Admin)) { # ----- F
			      Start-Process "$psHome\powershell.exe" -Verb Runas -ArgumentList $arg 
			      break 
		   		} 
			Else {
				Write-Host "Already running as Admin no need to restart..."
		}
	} 
	else 
	{ 
	   return "Error - Script is not saved" 
	   break 
	} 
}


function bits {
$bitsjobs = Get-BitsTransfer -AllUsers
$bitsjobs | Format-Table -AutoSize
$bitsjobs.count
$bitscurrent = $bitsjobs | where JobState -like Transferring
$guid = ($bitscurrent.jobId).Guid
If ($bitscurrent -ne $null)
    {
    $guid
    Start-Process -FilePath cmd -ArgumentList "/c BCmon.exe /BITS /Realtime $guid ResultFilename.csv" -Wait
	timeout 5
    bits
    }
Else 
    {
    $answer = Read-Host "Try again (Y/N) ?"
    if ($answer -like "Y*")
        {
        bits
        }

    }
}
#endregion Functions


Restart-ScriptAsAdmin

bits 
