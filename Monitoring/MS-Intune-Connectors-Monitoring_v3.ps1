<#
.SYNOPSIS
    This script is provided As Is with no support. You can contact me on github or linkedin if you have any question or remark.

.DESCRIPTION
	Proactive monitoring of Intune and W365

.PARAMETER Type

.NOTES
    Version: 3.0
    Author: Nicolas CHEYMOL
    Website : https://github.com/ncheymol
    Created: 01/11/2024
    Updated: 06/06/2024

.HISTORY 
    1.0 - Script created
    1.2 - Add tag to notify only once per day that the ANC is unhealthy, tag is removed once healthy
    3.0 - Transform script to use variables

.LINK 

.COPYRIGHT
This project is licensed under the Creative Commons Attribution-NonCommercial 4.0 International Public License (CC BY-NC 4.0).

## License

You are free to:
- Share: copy and redistribute the material in any medium or format
- Adapt: remix, transform, and build upon the material

Under the following terms:
- Attribution: You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
- NonCommercial: You may not use the material for commercial purposes.

No additional restrictions: You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.

For more details, please refer to the [full license text](LICENSE).

## Author

This project is created by Nicolas CHEYMOL. Please make sure to credit me as the original author when using or modifying this project.
#>

# Variables
$CertIssuer = "CERTIFICATE_ISSUER" # Placeholder for certificate issuer
$AppId = 'APPLICATION_ID' # Placeholder for application ID
$TenantId = 'TENANT_ID' # Placeholder for tenant ID
$mailaddress = "EMAIL_ADDRESS" # Placeholder for email address
$addhours = -0.5 # Number of hours to look back for W365 provisioning and other events

#region functions
function Ensure-Module 
    {
    param (
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    if (-not (Get-Module -ListAvailable -Name $ModuleName))
        {
        Write-Host "Installing module $ModuleName ..."
        Try 
            {
            Install-Module -Name $ModuleName -Scope CurrentUser -AllowClobber -Verbose
            }
        Catch 
            {
            Write-Error "Failed to install $ModuleName"
            Break
            }
        }
    Import-Module $ModuleName -Verbose
}

function Send-OutlookMail 
    {
    param (
        [Parameter(Mandatory)]
        [string]$To,
        [string]$Cc,
        [Parameter(Mandatory)]
        [string]$Subject,
        [Parameter(Mandatory)]
        [string]$Body
    )
    $Outlook = New-Object -comObject Outlook.Application
    $Mail = $Outlook.CreateItem(0)
    $Mail.To = $To
    if ($Cc) { $Mail.Cc = $Cc }
    $Mail.Subject = $Subject
    $Mail.Body = $Body
    $Mail.Send()
    }

function Remove-TagFiles 
    {
    param (
        [Parameter(Mandatory)]
        [string[]]$TagFiles
    )

    foreach ($file in $TagFiles) 
        {
        Remove-Item -Path $file -ErrorAction Ignore
        }
}

function Start-OutlookIfNeeded 
    {
    param (
        [string]$TagFile,
        [array]$Groups
    )
    if (!(Test-Path $TagFile)) 
        {
        if ((Get-Process -Name outlook -ErrorAction Ignore) -ne $null)   
            {
            Stop-Process -Name outlook
            Start-Process -FilePath "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"
            Start-Sleep -Seconds 30
            "done" | Out-File -FilePath $TagFile
            }
        }
    elseif ((Get-Process -Name outlook -ErrorAction Ignore) -eq $null) 
        {
        Start-Process -FilePath "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"
        Start-Sleep -Seconds 30
        }
    }

function Connect-EntraID 
    {
    param (
        [string]$CertIssuer,
        [string]$TenantId,
        [string]$AppId
    )

    Try 
        {
        $Cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Issuer.StartsWith("$($CertIssuer)") }
        Connect-MgGraph -TenantId $TenantId -ClientId $AppId -Certificate $Cert 
        }
    Catch 
        {
        Write-Host "Erreur lors de la connexion à MS Graph : $_"
        Break
        }
    }

function Process-NDESConnectors 
    {
    param (
        [string]$MailToNDES,
        [string]$MailCcNDES
    )
    Write-Output  "$(get-date) ################# Certificate Connectors ########################"
    $URI = "https://graph.microsoft.com/beta/deviceManagement/ndesConnectors"
    $connectors =  Invoke-MgGraphRequest -Method GET -Uri $uri -ContentType "application/json"
    foreach ($connector in $connectors.value) 
        {
        $uri = "https://graph.microsoft.com/beta/deviceManagement/certificateConnectorDetails/$($connector.id)"
        $connectordetails =  Invoke-MgGraphRequest -Method GET -Uri $uri -ContentType "application/json"
        $pageContent = (Invoke-WebRequest -Uri "https://learn.microsoft.com/en-us/mem/intune/protect/certificate-connector-overview#whats-new-for-the-certificate-connector").Content
        $versionNumbers = $pageContent -split "`n" | Select-String -Pattern "<p>Version <strong>"
        $availableversions = $versionNumbers -replace '.*?<strong>', '' -replace '</strong>.*', ''
        $msg = "
        ID : $($connector.id)
        Nom : $($connector.displayName)
        Statut: $($connector.state)
        Dernière synchronisation : $($connector.lastConnectionDateTime)
        enrollmentDateTime : $($connectordetails.enrollmentDateTime)
        connectorVersion : $($connectordetails.connectorVersion)
        latestVersion : $($availableversions.GetValue(0))
        "
        Write-Output $msg
        $tagfile = "C:\temp\MS-Intune-Connector-Monitoring\$($connector.displayName)_failed_$(get-date -Format yyyMMdd).txt"
        $tagfile2 = "C:\temp\MS-Intune-Connector-Monitoring\$($connector.displayName)_Update_$(get-date -Format yyyMM).txt"
        if ($($connector.state) -ne "active") 
            {
            if (!(Test-Path $tagfile)) 
                {
                Send-OutlookMail -To $MailToNDES -Cc $MailCcNDES -Subject "Alerte NDES : $($connector.displayName)" -Body $msg
                }
            $msg | Out-File -FilePath $tagfile
            }
        elseif ($availableversions.GetValue(0) -gt $connectordetails.connectorVersion) 
            {
            if (!(Test-Path $tagfile2)) 
                {
                Send-OutlookMail -To $MailAddress -Subject "Information NDES : $($connector.displayName)" -Body $msg
                }
            $msg | Out-File -FilePath $tagfile2
            }
        elseif ((Test-Path $tagfile)) 
            {
            Remove-TagFiles -TagFiles @($tagfile)
            Send-OutlookMail -To $MailToNDES -Cc $MailCcNDES -Subject "Alerte NDES : $($connector.displayName)" -Body "issue solved, server is now healthy`n$msg"
            }
        else 
            {
            Remove-TagFiles -TagFiles @($tagfile, $tagfile2)
            }
        }
    }

function Process-Tunnel 
    {
    param (
        [string]$MailToTunnel,
        [string]$MailCcTunnel
    )
    Write-Output  "$(get-date) ####################### MS Tunnel #############################"
    $URI = "https://graph.microsoft.com/beta/deviceManagement/microsoftTunnelSites/"
    $tunnelsites =  Invoke-MgGraphRequest -Method GET -Uri $uri -ContentType "application/json"

    foreach ($tunnelsite in $tunnelsites.value) 
        {
        $URI = "https://graph.microsoft.com/beta/deviceManagement/microsoftTunnelSites/$($tunnelsite.id)/microsoftTunnelServers/"
        $tunnelservers =  Invoke-MgGraphRequest -Method GET -Uri $uri -ContentType "application/json"
        
        foreach ($tunnelserver in $tunnelservers.value) 
            {
            $URI = "https://graph.microsoft.com/beta/deviceManagement/microsoftTunnelSites/$($tunnelsite.id)/microsoftTunnelServers/$($tunnelserver.id)"
            $tunnel =  Invoke-MgGraphRequest -Method GET -Uri $uri -ContentType "application/json"
            
            $healthURI = "https://graph.microsoft.com/beta/deviceManagement/microsoftTunnelSites/$($tunnelsite.id)/microsoftTunnelServers/$($tunnelserver.id)/getHealthMetrics"
            function Get-Metric 
                { 
                param($metric) 
                (Invoke-MgGraphRequest -Method POST -Uri $healthURI -ContentType "application/json" -Body (@{"metricNames"=@($metric)} | ConvertTo-Json)).value.value 
                }

            $connectionFailures = Get-Metric "connectionFailures"
            $currentConnections = Get-Metric "currentConnections"
            $throughput = Get-Metric "throughput"
            $cpuUsage = Get-Metric "cpuUsage"
            $cpuCores = Get-Metric "cpuCores"
            $memoryUsage = Get-Metric "memoryUsage"
            $tlsCert = Get-Metric "tlsCert"
            $tlsCertRevocation = Get-Metric "tlsCertRevocation"
            $agentCert = Get-Metric "agentCert"
            $latency = Get-Metric "latency"
            $diskSpaceUsage = Get-Metric "diskSpaceUsage"
            $totalDiskSpace = Get-Metric "totalDiskSpace"
            $upgradeability = Get-Metric "upgradeability"
            $serverVersion = Get-Metric "serverVersion"
            $onPremNetworkAccess = Get-Metric "onPremNetworkAccess"
            $serverConfiguration = Get-Metric "serverConfiguration"
            $serverContainer = Get-Metric "serverContainer"
            $serverLogs = Get-Metric "serverLogs"

            $msg = "
            ID: $($tunnel.id)
            Name: $($tunnel.displayName)
            Status: $($tunnel.tunnelServerHealthStatus)
            Last Status Update: $($tunnel.lastCheckinDateTime)
            ################ Usage ################
            connectionFailures : $connectionFailures
            currentConnections : $currentConnections
            throughput : $throughput
            ################ Health ################
            cpuUsage : $cpuUsage
            cpuCores : $cpuCores
            memoryUsage : $memoryUsage %
            tlsCert : $tlsCert days
            tlsCertRevocation : $tlsCertRevocation
            agentCert : $agentCert days
            latency : $latency ms
            diskSpaceUsage :$($diskSpaceUsage/1024/1024) GB available
            totalDiskSpace : $($totalDiskSpace/1024/1024) GB
            serverVersion : $serverVersion (1 : Up-to-Date | 2 : One update available | 3 : 2+ updates available)
            onPremNetworkAccess : $onPremNetworkAccess
            serverConfiguration : $serverConfiguration
            serverContainer : $serverContainer
            serverLogs : $serverLogs
            "
            Write-Output $msg
            $tagfile = "C:\temp\MS-Intune-Connector-Monitoring\$($tunnel.displayName)_failed_$(get-date -Format yyyMMdd).txt"
            $tagfile2 = "C:\temp\MS-Intune-Connector-Monitoring\$($tunnel.displayName)_Update_$($upgradeability)_$(get-date -Format yyyMM).txt"
            if ($serverConfiguration -ne 1 -or $serverContainer -ne 1 -or $currentConnections -ge 5000) 
                {
                if (!(Test-Path $tagfile)) 
                    {
                    Send-OutlookMail -To $MailToTunnel -Cc $MailCcTunnel -Subject "Alerte Tunnel : $($tunnel.displayName)" -Body $msg
                    }
                $msg | Out-File -FilePath $tagfile
                }
            elseif ($serverVersion -gt 1) 
                {
                if (!(Test-Path $tagfile2)) 
                    {
                    Send-OutlookMail -To $MailToTunnel -Cc $MailCcTunnel -Subject "Information Tunnel : $($tunnel.displayName)" -Body $msg
                    }
                $msg | Out-File -FilePath $tagfile2
                }
            else 
                {
                Remove-TagFiles -TagFiles @($tagfile, $tagfile2)
                }
            }
        }
    }

function Process-HDJ 
    {
    param (
        [string]$MailToHDJ,
        [string]$MailCcHDJ
    )
    Write-Output  "$(get-date) #################### HDj connector ###########################"
    $URI = "https://graph.microsoft.com/beta/deviceManagement/domainJoinConnectors"
    $connectorsAD =  Invoke-MgGraphRequest -Method GET -Uri $uri -ContentType "application/json"
    foreach ($connectorAD in $connectorsAD.value) {
        $msg = "
        ID: $($connectorAD.id)
        Nom: $($connectorAD.displayName)
        Statut: $($connectorAD.state)
        Dernière mise à jour: $($connectorAD.lastConnectionDateTime) UTC
        "
        Write-Output $msg
        $tagfile = "C:\temp\MS-Intune-Connector-Monitoring\$($connectorAD.displayName)_failed_$(get-date -Format yyyMMdd)_$($connectorAD.id).txt"
        if ($($connectorAD.state) -ne "active") 
            {
            if (!(Test-Path $tagfile)) 
                {
                Send-OutlookMail -To $MailToHDJ -Cc $MailCcHDJ -Subject "Alerte AD Connector : $($connectorAD.displayName)" -Body $msg
                }
            $msg | Out-File -FilePath $tagfile
            }
        elseif (Test-Path $tagfile) 
            {
            Remove-TagFiles -TagFiles @($tagfile)
            Send-OutlookMail -To $MailToHDJ -Cc $MailCcHDJ -Subject "Alerte AD Connector : $($connectorAD.displayName)" -Body "issue solved, server is now healthy`n$msg"
            }
        }
    }

function Process-ANC 
    {
    param (
        [string]$MailToANC,
        [string]$MailCcANC
    )

    Write-Output  "$(get-date) ####################### ANC W365 ############################"
    $URI = "https://graph.microsoft.com/beta/deviceManagement/virtualEndpoint/onPremisesConnections"
    $connectorsANC =  Invoke-MgGraphRequest -Method GET -Uri $uri -ContentType "application/json"
    foreach ($connectorANC in $connectorsANC.value) 
        {
        $uri = "https://graph.microsoft.com/beta/deviceManagement/virtualEndpoint/onPremisesConnections/$($connectorANC.id)?select=healthCheckStatusDetails"
        $healthCheckStatusDetails =  Invoke-MgGraphRequest -Method GET -Uri $uri -ContentType "application/json"
        $healthCheckStatusDetails = $($healthCheckStatusDetails.healthCheckStatusDetails.healthChecks)
        $healthCheckStatusmsg = ""
        foreach ($healthCheckStatusDetail in $healthCheckStatusDetails) 
            {
            $healthCheckStatusmsg += "$($healthCheckStatusDetail.endDateTime) - $($healthCheckStatusDetail.displayName) : $($healthCheckStatusDetail.status)`n        "
            }

        $msg = "
        displayName: $($connectorANC.displayName)
        adDomainName: $($connectorANC.adDomainName)
        id: $($connectorANC.id)
        healthCheckStatus: $($connectorANC.healthCheckStatus)
        healthCheckStatusmsg: 
        $healthCheckStatusmsg
        Other:
        connectionType: $($connectorANC.connectionType)
        managedBy: $($connectorANC.managedBy)
        type: $($connectorANC.type)
        organizationalUnit: $($connectorANC.organizationalUnit)
        adDomainUsername: $($connectorANC.adDomainUsername)
        scopeIds: $($connectorANC.scopeIds)
        subscriptionName: $($connectorANC.subscriptionName)
        subscriptionId: $($connectorANC.subscriptionId)
        virtualNetworkLocation: $($connectorANC.virtualNetworkLocation)
        resourceGroupId: $($connectorANC.resourceGroupId)
        virtualNetworkId: $($connectorANC.virtualNetworkId)
        subnetId: $($connectorANC.subnetId)
        "
        Write-Output $msg

        if ($($healthCheckStatusDetails.GetValue(0).status) -eq "Warning" -and 
            ($healthCheckStatusDetails.values | Select-String "Warning").count -eq 1 -and 
            ($healthCheckStatusDetails.values | Select-String "failed").count -eq 0) 
            {
            $connectorANC.healthCheckStatus = "passed"
            }

        $tagfile = "C:\temp\MS-Intune-Connector-Monitoring\$($connectorANC.displayName)_failed_$(get-date -Format yyyMMdd).txt"
        if ($($connectorANC.healthCheckStatus) -ne "passed" -and $($connectorANC.healthCheckStatus) -ne "running" -and $($connectorANC.healthCheckStatus) -ne "pending" -and $($connectorANC.healthCheckStatus) -ne "informational") 
            {
            if (!(Test-Path $tagfile)) 
                {
                Send-OutlookMail -To $MailToANC -Cc $MailCcANC -Subject "Alerte ANC : $($connectorANC.displayName)" -Body $msg
                }
            $msg | Out-File -FilePath $tagfile
            }
        else 
            {
            Remove-TagFiles -TagFiles @($tagfile)
            }
        }
    }

function Process-W365Provisioning 
    {
    param (
        [string]$MailCcW365,
        [string]$AddHours
    )

    Write-Output  "$(get-date) ################# W365 Provisioning ########################"
    $currentDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    $pastdate = (Get-Date).ToUniversalTime().AddHours($AddHours).ToString("yyyy-MM-ddTHH:mm:ss.000Z")
    $uri = "https://graph.microsoft.com/beta/deviceManagement/auditEvents?`$filter=activityType eq 'UpdateDevicePrimaryUsers ManagedDevice' and activityDateTime gt $pastdate and activityDateTime le $currentdate&`$orderby=activityDateTime desc"
    $audits =  Invoke-MgGraphRequest -Method GET -Uri $uri -ContentType "application/json"
    foreach ($audit in $audits.value) 
        {
        $applicationDisplayName = $audit.actor.applicationDisplayName
        if ($applicationDisplayName -eq "Windows 365") 
            {
            $userid = $($audit.resources.modifiedProperties.newvalue.Item(1))
            $deviceid = $audit.resources.resourceId
            $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($deviceid)"
            $device = Invoke-MgGraphRequest -Method GET -Uri $uri -ContentType "application/json"
            $deviceName = $device.deviceName
            $UPN = $device.userPrincipalName
            $uri = "https://graph.microsoft.com/v1.0/users/$($userid)"
            $user = Invoke-MgGraphRequest -Method GET -Uri $uri -ContentType "application/json"
            $uri = "https://graph.microsoft.com/v1.0/users/$($userid)/manager"
            $manager = Invoke-MgGraphRequest -Method GET -Uri $uri -ContentType "application/json"
            $msg = "
            Your Cloud PC is ready, start the Windows App to connect
            deviceName: $($deviceName)
            deviceid: $($audit.resources.resourceId)
            userid: $($userid)
            UPN: $($UPN)
            Last Update: $($audit.activityDateTime) UTC
            "
            Write-Output $msg
            Send-OutlookMail -To $UPN -Cc $MailAddress -Subject "New CloudPC provisionned for $($user.displayName)" -Body $msg
            }
        }
    }
#endregion


#region MAIN SCRIPT
$directory = "C:\temp\MS-Intune-Connector-Monitoring"
$filePattern = "MS-Intune-Connector-Monitoring_"
$timeLimit = (Get-Date).AddHours($AddHours)
$lastlogs = Get-ChildItem -Path $directory -Filter "$filePattern*" | Where-Object { $_.CreationTime -gt $timeLimit }
$currentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$csvFilePath = "C:\temp\MS-Intune-Connector-Monitoring\lastlogs_count.csv"
$csvContent = "$currentDateTime;$($lastlogs.count)"
$csvContent | Out-File -FilePath $csvFilePath -Encoding utf8 -Append
if ($lastlogs.count -gt 0) { Exit }

Start-Transcript -Path "C:\temp\MS-Intune-Connector-Monitoring\MS-Intune-Connector-Monitoring_$(get-date -Format yyyMMddhhmmss).log" -Append

#region outlook
Write-Output  "$(get-date) ################# Start Outlook ########################"
$tagfile = "C:\temp\MS-Intune-Connector-Monitoring\Outlook_$(get-date -Format yyyMMdd).txt"
Start-OutlookIfNeeded -TagFile $tagfile -Groups $groups
#endregion

#region auth
Write-Output  "$(get-date) ################# Connect Entra ID ########################"
$Modules = @("Microsoft.Graph.Authentication","Microsoft.Graph.Beta.DeviceManagement.Administration") 
$Modules | ForEach-Object { Ensure-Module -ModuleName $_ }
Import-Module Microsoft.Graph.Authentication
Connect-EntraID -CertIssuer $CertIssuer -TenantId $TenantId -AppId $AppId
#endregion

Process-NDESConnectors -MailToNDES "MacOSForDevBacklog@saintgobain.onmicrosoft.com;dl-pcgroupsolution-master@saint-gobain.com" -MailCcNDES $mailaddress
Process-Tunnel -MailToTunnel "dl-mobility.project@saint-gobain.com" -MailCcTunnel $mailaddress
Process-HDJ -MailToHDJ "dl-pcgroupsolution-master@saint-gobain.com" -MailCcHDJ $mailaddress
Process-ANC -MailToANC "dl-pcgroupsolution-master@saint-gobain.com" -MailCcANC $mailaddress
Process-W365Provisioning -MailCcW365 $mailaddress -AddHours $addhours

Stop-Transcript

#endregion