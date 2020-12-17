#Author : Nicolas CHEYMOL
#Date : 05/2019
#Source : https://github.com/ncheymol

# Variables
#$BackupsFoler = "D:\temp\IntuneBackup"
$logdate = get-date -format "dd-MM-yyyy"
Start-Transcript -path "$env:TEMP\IntuneBackup_$logdate.log"
### BackupsFoler
if ($null -eq $ReferenceFilePath)
{
[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
$OpenFileDialog = New-Object System.Windows.Forms.FolderBrowserDialog
$OpenFileDialog.SelectedPath = $BackupsFoler
$OpenFileDialog.ShowNewFolderButton = $true
$OpenFileDialog.Description = "Select a directory"
$OpenFileDialog.ShowDialog() | Out-Null
$BackupsFoler = $OpenFileDialog.SelectedPath
}

$BackupPath = "$BackupsFoler\$logdate"

# Enter the credentials for an Intune Administrator.
if ($null -eq $credential)
    {
        $Credential = Get-Credential
    }

# function test Admin Rights to install Module
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


# function Get Admin consent to connect to Intune Powershell
function Get-AuthToken {

    <#
    .SYNOPSIS
    This function is used to authenticate with the Graph API REST interface
    .DESCRIPTION
    The function authenticate with the Graph API Interface with the tenant name
    .EXAMPLE
    Get-AuthToken
    Authenticates you with the Graph API interface
    .NOTES
    NAME: Get-AuthToken
    #>
    
    [cmdletbinding()]
    
    param
    (
        [Parameter(Mandatory=$true)]
        $User
    )
    
    $userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $User
    
    $tenant = $userUpn.Host
    
    Write-Host "Checking for AzureAD module..."
    
        $AadModule = Get-Module -Name "AzureAD" -ListAvailable
    
        if ($AadModule -eq $null) {
    
            Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
            $AadModule = Get-Module -Name "AzureADPreview" -ListAvailable
    
        }
    
        if ($AadModule -eq $null) {
            write-host
            write-host "AzureAD Powershell module not installed..." -f Red
            write-host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
            write-host "Script can't continue..." -f Red
            write-host
            exit
        }
    
    # Getting path to ActiveDirectory Assemblies
    # If the module count is greater than 1 find the latest version
    
        if($AadModule.count -gt 1){
    
            $Latest_Version = ($AadModule | select version | Sort-Object)[-1]
    
            $aadModule = $AadModule | ? { $_.version -eq $Latest_Version.version }
    
                # Checking if there are multiple versions of the same module found
    
                if($AadModule.count -gt 1){
    
                $aadModule = $AadModule | select -Unique
    
                }
    
            $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
            $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
    
        }
    
        else {
    
            $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
            $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
    
        }
    
    [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
    
    [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
    
    $clientId = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"
    
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
    
    $resourceAppIdURI = "https://graph.microsoft.com"
    
    $authority = "https://login.microsoftonline.com/$Tenant"
    
        try {
    
        $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
    
        # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
        # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession
    
        $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"
    
        $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId")
    
        $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$clientId,$redirectUri,$platformParameters,$userId,"prompt=admin_consent").Result
    
            if($authResult.AccessToken){
    
            # Creating header for Authorization token
    
            $authHeader = @{
                'Content-Type'='application/json'
                'Authorization'="Bearer " + $authResult.AccessToken
                'ExpiresOn'=$authResult.ExpiresOn
                }
    
            return $authHeader
    
            }
    
            else {
    
            Write-Host
            Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
            Write-Host
            break
    
            }
    
        }
    
        catch {
    
        write-host $_.Exception.Message -f Red
        write-host $_.Exception.ItemName -f Red
        write-host
        break
    
        }
    
    }
    

try 
{
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
    }
catch 
    {
    Write-Host "Failed to Import Modules" -ForegroundColor Red        
    }

# Connect to Microsoft Graph
try 
    {
    Connect-Graph -Credential $Credential -ErrorAction Stop
    }
catch 
    {
        Write-Host "catch"
    try 
        {
        if ($null -eq (Get-InstalledModule -Name AzureAD))
            {
            Restart-ScriptAsAdmin
            Install-Module -Name AzureAD
            }
        if ($null -eq (Get-Module -Name AzureAD))
            {
            Import-Module -Name AzureAD
            }

        }
    catch 
        {
        Write-Host "failed to import AzureAD Module"
        }
    try 
        {
        Get-AuthToken -User $credential.UserName -ErrorAction Stop 
        }
    catch
        {    
            Write-host "failed to get rigths"
        }
    }
# Backup Intune
try 
    {
    Start-IntuneBackup -Path $BackupPath    }
catch 
    {
    Write-Host "Failed to Fully backup Intune" -ForegroundColor Red        
    }

Stop-Transcript
