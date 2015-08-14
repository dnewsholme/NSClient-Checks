<#

.SYNOPSIS
Returns Summary of Active Messages in RabbitMQ requires rabbitMQtools module https://github.com/RamblingCookieMonster/RabbitMQTools/archive/master.zip

.DESCRIPTION
Returns Summary of Active Messages in RabbitMQ with their states.

.PARAMETER hostname
RabbitMQ hostname https://lb-pd-rabbitmq:15671

.PARAMETER Username
Username used to access the rabbitmq web interface

.PARAMETER Password
Password used to access the rabbitmq web interface

.PARAMETER VirtualHost 
The Name of the virtual host as listed within the rabbitMQ web interface

.PARAMETER Queuename
The Name of the queue to be checked.

.PARAMETER Warning
The value for warning unacked messages

.PARAMETER Critical
The crit value for unacked messages

.EXAMPLE
check-rabbitmqqueue.ps1 -hostname "lb-pd-rabbitmq" -VirtualHost "Blaze" -queuename "Q.DecisionPending" -username "rabbit.admin" -password "Purp13RA1n" -warning 10 -Critical 1000

.NOTES
Daryl Bizsley 2015

#>  
    param (
    $hostname = $env:computername,
    $username,
    $password,
    $VirtualHost,
    $queuename,
    [int32]$warning,
    [int32]$Critical
    )
    #Convert password to a secure string type
    $passwordAsSecureString = ConvertTo-SecureString "$password" -AsPlainText -Force
    $cred = new-object System.Management.Automation.PSCredential ("$username", $passwordAsSecureString)
    #Import rabbitmq tools Import-module
    try{
        Import-module RabbitMQTools -ErrorAction Stop
    }
    catch [System.IO.FileNotFoundException]{
        'RabbitMQTools Powershell module not found:{0}' -f $Error[0].Exception
        $nagiosexitcode = 4
        exit $nagiosexitcode
    }
    #Try to connect to server and retrieve details
    try {
        $result = Get-RabbitMQQueue -VirtualHost $VirtualHost -BaseUri ("https://{0}:15671" -f $hostname) -Credentials $cred -ErrorAction Stop
        }
    catch [System.Net.WebException] {
        #Catch and return errors exiting with unknown state
         return $Error[0].Exception
         exit $nagiosexitcode = 4
    } 
    #Limit to the queue we are interested in
    $result = $result | where {$_.Name -eq $queuename}
    if (!($result)){
        "No queue matching $queuename found. The name must be the same as in rabbitmq including case sensitivity"
        $nagiosexitcode 4
        exit $nagiosexitcode
    }
    #Check if the queue size has reached Critical or warning levels and set exitcode appropriately.
    if ($result.Messages -ge $Critical){
        $nagiosexitcode = 2
        }
    ELSEIF ($result.Messages -ge $warning){
        $nagiosexitcode = 1
        }
    #Otherwise set to ok
    Else {$nagiosexitcode = 0}
    #Create a new custom object to store our data for neatness
    $output = New-Object psobject
    $output | Add-Member -Type NoteProperty -Name "Name" -Value $result.Name
    $output | Add-Member -Type NoteProperty -Name "Messages" -Value $result.Messages
    #Use of regex to remove the dirty text and get the number we are interested in and convert from a string to a Decimal type
    $output | Add-Member -Type NoteProperty -Name "Message_Rate(\S)" -Value ([Decimal]((($result.Messages_details | Select-String -Pattern "[0-9]*\.[0-9]" -AllMatches).Matches).Value))
    #Create the performance data to output to nagios later ensuring the correct formatting.
    $output | Add-Member -Type NoteProperty -Name "Perfdata" -Value ("'Messages Total'={0};$warn;$crit;; 'Current Message Rate'={1};;;;" -f $result.Messages,$output.'Message_Rate(\S)')
    $output | Add-Member -Type NoteProperty -Name "Idle_Since" -Value $result.idle_since
    $output | add-Member -Type NoteProperty -Name "NagiosExitcode" -Value $nagiosexitcode
    #Output the fields we want to see only.
    $final = $output | select Name,Messages,'Message_Rate(\S)',Idle_Since
    #Write out to stdout for nagios including our Perfdata
    $final  
    '|{0}' -f $output.Perfdata
    #Exit with the exitcode set earlier
    Exit $nagiosexitcode
