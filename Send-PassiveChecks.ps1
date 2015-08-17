<#

.SYNOPSIS
Sends a passive result check to nagios nsca

.DESCRIPTION
Sends a passive result check to nagios nsca

.PARAMETER SeviceDescription
The name of the servicecheck as it appears in nagios(This must match for the check to be processed)

.PARAMETER ReturnCode
The exitcode to report to nagios

.PARAMETER OutputMessage
The text to accompany the status reported to nagios

.EXAMPLE
Send-PassiveCheck -Servicedescription "Invalid Logon Attempts" -ReturnCode "2" -outputmessage "50 Invalid logon attempts in the last 5 minutes"

.NOTES
Daryl Bizsley 2015

#>


function Send-PassiveCheck {
    Param(
        $servicedescription,
        [int]$returncode,
        $outputmessage
        )
    #Get time in Unix Epoch Format as specified by the nagios passive check Format
    $timestamp=[Math]::Floor([decimal](Get-Date(Get-Date).ToUniversalTime()-uformat "%s"))
    
    #check if servicecheck or hostcheck result and set output text appropriately
    $processcommand = "PROCESS_SERVICE_CHECK_RESULT"
    #Set the output message to return via nsca
    $output = '[{0}] {1};{2};{3};{4};{5}' -f $timestamp,$processcommand,$env:computername;$servicedescription;$returncode;$outputmessage
    return $output 
}
