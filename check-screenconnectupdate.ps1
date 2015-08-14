<#

.SYNOPSIS
Checks the screenconnect website to see if a new release is available.

.NOTES
Daryl Bizsley 2015

#>

$appversion = ((((Get-Item "C:\Program Files (x86)\ScreenConnect\Bin\ScreenConnect.Service.exe").VersionInfo).ProductVersion).Replace(" ","")).Replace(",",".")
$result = Invoke-WebRequest -Uri https://www.screenconnect.com/Download -usebasicparsing
$Currentversion = $result.Content | Select-String -Pattern "ScreenConnect_+[0-9].[0-9].[0-9][0-9][0-9][0-9].[0-9][0-9][0-9][0-9]_Release.msi" | % {$_.Matches} | % {$_.Value}
$currentversion = $currentversion.replace("ScreenConnect_","")
$currentversion = $currentversion.replace("_Release.msi","")
if ($Currentversion -gt $appversion){
    $Currentversion = $Currentversion.Replace("Changes in", "")
    write-output "Update Available: $Currentversion `n Currently installed is $appversion `n Update details: https://www.screenconnect.com/Download"
    $exitcode = 1
}
Else {write-output "Server is currently up to date $appversion"
    $exitcode = 0
}
IF ($error -ne $null){
    write-output $error
$exitcode = 2
}
exit $exitcode
