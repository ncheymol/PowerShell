﻿#Author : Nicolas CHEYMOL
#Date : 09/2014
#Source : https://github.com/ncheymol

$domain = ".domain.local"

$host.ui.RawUI.WindowTitle = "CM_PMAD-Debug"
function Test-Port{ 
<#   
.SYNOPSIS   
    Tests port on computer. 
.DESCRIPTION 
    Tests port on computer. 
.PARAMETER computer 
    Name of server to test the port connection on. 
.PARAMETER port 
    Port to test   
.PARAMETER tcp 
    Use tcp port  
.PARAMETER udp 
    Use udp port  
.PARAMETER UDPTimeOut
    Sets a timeout for UDP port query. (In milliseconds, Default is 1000)   
.PARAMETER TCPTimeOut
    Sets a timeout for TCP port query. (In milliseconds, Default is 1000)            
.NOTES   
    Name: Test-Port.ps1 
    Author: Boe Prox 
    DateCreated: 18Aug2010  
    List of Ports: http://www.iana.org/assignments/port-numbers 
     
    To Do: 
        Add capability to run background jobs for each host to shorten the time to scan.        
.LINK   
    https://boeprox.wordpress.org 
.EXAMPLE   
    Test-Port -computer 'server' -port 80 
    Checks port 80 on server 'server' to see if it is listening 
.EXAMPLE   
    'server' | Test-Port -port 80 
    Checks port 80 on server 'server' to see if it is listening  
.EXAMPLE   
    Test-Port -computer @("server1","server2") -port 80 
    Checks port 80 on server1 and server2 to see if it is listening    
.EXAMPLE   
    @("server1","server2") | Test-Port -port 80 
    Checks port 80 on server1 and server2 to see if it is listening   
.EXAMPLE   
    (Get-Content hosts.txt) | Test-Port -port 80 
    Checks port 80 on servers in host file to see if it is listening 
.EXAMPLE   
    Test-Port -computer (Get-Content hosts.txt) -port 80 
    Checks port 80 on servers in host file to see if it is listening    
.EXAMPLE   
    Test-Port -computer (Get-Content hosts.txt) -port @(1..59) 
    Checks a range of ports from 1-59 on all servers in the hosts.txt file     
           
#>  
[cmdletbinding( 
    DefaultParameterSetName = '', 
    ConfirmImpact = 'low' 
)] 
    Param( 
        [Parameter( 
            Mandatory = $True, 
            Position = 0, 
            ParameterSetName = '', 
            ValueFromPipeline = $True)] 
            [array]$computer, 
        [Parameter( 
            Position = 1, 
            Mandatory = $True, 
            ParameterSetName = '')] 
            [array]$port, 
        [Parameter( 
            Mandatory = $False, 
            ParameterSetName = '')] 
            [int]$TCPtimeout=1000, 
        [Parameter( 
            Mandatory = $False, 
            ParameterSetName = '')] 
            [int]$UDPtimeout=1000,            
        [Parameter( 
            Mandatory = $False, 
            ParameterSetName = '')] 
            [switch]$TCP, 
        [Parameter( 
            Mandatory = $False, 
            ParameterSetName = '')] 
            [switch]$UDP             
                         
        ) 
    Begin { 
        If (!$tcp -AND !$udp) {$tcp = $True} 
        #Typically you never do this, but in this case I felt it was for the benefit of the function 
        #as any errors will be noted in the output of the report         
        $ErrorActionPreference = "SilentlyContinue" 
        $report = @() 
        } 
    Process {    
        ForEach ($c in $computer) { 
            ForEach ($p in $port) { 
                If ($tcp) {   
                    #Create temporary holder  
                    $temp = "" | Select Server, Port, TypePort, Open, Notes 
                    #Create object for connecting to port on computer 
                    $tcpobject = new-Object system.Net.Sockets.TcpClient 
                    #Connect to remote machine's port               
                    $connect = $tcpobject.BeginConnect($c,$p,$null,$null) 
                    #Configure a timeout before quitting 
                    $wait = $connect.AsyncWaitHandle.WaitOne($TCPtimeout,$false) 
                    #If timeout 
                    If(!$wait) { 
                        #Close connection 
                        $tcpobject.Close() 
                        Write-Verbose "Connection Timeout" 
                        #Build report 
                        $temp.Server = $c 
                        $temp.Port = $p 
                        $temp.TypePort = "TCP" 
                        $temp.Open = "False" 
                        $temp.Notes = "Connection to Port Timed Out" 
                        } 
                    Else { 
                        $error.Clear() 
                        $tcpobject.EndConnect($connect) | out-Null 
                        #If error 
                        If($error[0]){ 
                            #Begin making error more readable in report 
                            [string]$string = ($error[0].exception).message 
                            $message = (($string.split(":")[1]).replace('"',"")).TrimStart() 
                            $failed = $true 
                            } 
                        #Close connection     
                        $tcpobject.Close() 
                        #If unable to query port to due failure 
                        If($failed){ 
                            #Build report 
                            $temp.Server = $c 
                            $temp.Port = $p 
                            $temp.TypePort = "TCP" 
                            $temp.Open = "False" 
                            $temp.Notes = "$message" 
                            } 
                        #Successfully queried port     
                        Else{ 
                            #Build report 
                            $temp.Server = $c 
                            $temp.Port = $p 
                            $temp.TypePort = "TCP" 
                            $temp.Open = "True"   
                            $temp.Notes = "" 
                            } 
                        }    
                    #Reset failed value 
                    $failed = $Null     
                    #Merge temp array with report             
                    $report += $temp 
                    }     
                If ($udp) { 
                    #Create temporary holder  
                    $temp = "" | Select Server, Port, TypePort, Open, Notes                                    
                    #Create object for connecting to port on computer 
                    $udpobject = new-Object system.Net.Sockets.Udpclient($p) 
                    #Set a timeout on receiving message
                    $udpobject.client.ReceiveTimeout = $UDPTimeout
                    #Connect to remote machine's port               
                    Write-Verbose "Making UDP connection to remote server"
                    $udpobject.Connect("$c",$p)
                    #Sends a message to the host to which you have connected.
                    Write-Verbose "Sending message to remote host"
                    $a = new-object system.text.asciiencoding
                    $byte = $a.GetBytes("$(Get-Date)")
                    [void]$udpobject.Send($byte,$byte.length)
                    #IPEndPoint object will allow us to read datagrams sent from any source. 
                    Write-Verbose "Creating remote endpoint"
                    $remoteendpoint = New-Object system.net.ipendpoint([system.net.ipaddress]::Any,0)
                    
                    Try {
                        #Blocks until a message returns on this socket from a remote host.
                        Write-Verbose "Waiting for message return"
                        $receivebytes = $udpobject.Receive([ref]$remoteendpoint)
                        [string]$returndata = $a.GetString($receivebytes)
                        }

                    Catch {
                        If ($Error[0].ToString() -match "\bRespond after a period of time\b") {
                            #Close connection 
                            $udpobject.Close() 
                            #Make sure that the host is online and not a false positive that it is open
                            If (Test-Connection -comp $c -count 1 -quiet) {
                                Write-Verbose "Connection Open" 
                                #Build report 
                                $temp.Server = $c 
                                $temp.Port = $p 
                                $temp.TypePort = "UDP" 
                                $temp.Open = "True" 
                                $temp.Notes = ""
                                }
                            Else {
                                <#
                                It is possible that the host is not online or that the host is online, 
                                but ICMP is blocked by a firewall and this port is actually open.
                                #>
                                Write-Verbose "Host maybe unavailable" 
                                #Build report 
                                $temp.Server = $c 
                                $temp.Port = $p 
                                $temp.TypePort = "UDP" 
                                $temp.Open = "False" 
                                $temp.Notes = "Unable to verify if port is open or if host is unavailable."                                
                                }                        
                            }
                        ElseIf ($Error[0].ToString() -match "forcibly closed by the remote host" ) {
                            #Close connection 
                            $udpobject.Close() 
                            Write-Verbose "Connection Timeout" 
                            #Build report 
                            $temp.Server = $c 
                            $temp.Port = $p 
                            $temp.TypePort = "UDP" 
                            $temp.Open = "False" 
                            $temp.Notes = "Connection to Port Timed Out"                        
                            }
                        Else {
                            $udpobject.close()
                            }
                        }    
                    #Merge temp array with report             
                    $report += $temp 
                    }                                 
                } 
            }                 
        } 
    End { 
        #Generate Report 
        $report 
        }         
}

function execute 
    {
#Author : Nicolas CHEYMOL
#Date : 04/2014
#Source : https://github.com/ncheymol

    $nb = 0
    $logdate = get-date -format "MM-dd-yyyy_HH.mm.ss"

    echo "$comput;$env:USERNAME;$logdate" >> $env:temp\CM_PMAD-Debug.log

    $IPs = ([System.Net.Dns]::GetHostAddresses($comput)) |?{$_.scopeid -eq $null}|%{$_.ipaddresstostring}

    foreach ($IP in $IPs)
        {
        $nb = $nb + 1
        echo "IP: $IP"
        $Name = ([System.Net.Dns]::GetHostbyAddress("$IP")).HostName
        $Name
        
        if (-not ($comput -like $Name) -and -not($Name -eq $null) -and -not($comput -eq "$name"+".$domain"))
            {
            Echo "Erreur de résolution DNS ($comput - $IP - $Name)"
            }
        Else
            {
            ping $comput

            Test-Port -computer $comput -port 80
            Test-Port -computer $comput -port 135
            Test-Port -computer $comput -port 445
            Test-Port -computer $comput -port 2701
            Test-Port -computer $comput -port 2702

            invoke-command {net localgroup "Utilisateurs du contrôle à distance ConfigMgr"} -comp $comput
            }
        if ($Name -eq $null)
            {
            Echo "Erreur de résolution DNS inversée"
            }

        }

    Echo "Nombre d'IPs: $nb"

    $retry = read-host "Retry? O/N"

    if ($retry -like "O")
    {
        If ($comput -like $null)
        {
            $comput = read-host "Enter the computername"
        }
        execute
    } 

    }

##Code##
$comput = read-host "Enter the computername"
execute