#Author : Nicolas CHEYMOL
#Date : 04/2019
#Source : https://github.com/ncheymol

# Variables
$BackupsFoler = "D:\temp\IntuneBackup"
$logdate = get-date -format "dd-MM-yyyy"
$BackupPath = "$BackupsFoler\$logdate"

# Enter the credentials for an Intune Administrator.
if ($null -eq $credential)
    {
        $Credential = Get-Credential
    }

# test Admin Rights to install Module
Function Restart-ScriptAsAdmin
{
    function Test-Admin 
    {#-------------------------------------------------------------------------------
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


# Install Modules
if ($null -eq (Get-InstalledModule -Name MSGraphFunctions))
    {
        Restart-ScriptAsAdmin
        Install-Module -Name MSGraphFunctions
    }
if ($null -eq (Get-InstalledModule -Name IntuneBackupAndRestore))
    {
        Restart-ScriptAsAdmin
        Install-Module -Name IntuneBackupAndRestore
    }


# Import Modules
if ($null -eq (Get-Module -Name MSGraphFunctions))
    {
        Import-Module -Name MSGraphFunctions
    }
if ($null -eq (Get-Module -Name IntuneBackupAndRestore))
    {
        Import-Module -Name IntuneBackupAndRestore
    }


# Connect to Microsoft Graph
Connect-Graph -Credential $Credential

# Backup Intune
Start-IntuneBackup -Path $BackupPath
