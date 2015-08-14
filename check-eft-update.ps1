<#

.SYNOPSIS
Checks the globalscape EFT website to see if a new release is available.

.NOTES
Daryl Bizsley 2015

#>

$SFTPSrv = ((((Get-Item "C:\Program Files (x86)\Globalscape\EFT Server\cftpsai.exe").VersionInfo).ProductVersion).Replace(" ","")).Replace(",",".")
$SFTPSrv = $SFTPSrv.Substring(0,5)
$result = Invoke-WebRequest -Uri http://dynamic.globalscape.com/support/history-eft.aspx -UseBasicParsing
$Currentversion = $result.Content | Select-String -Pattern "Changes in+ [0-9].[0-9].[0-9]" | % {$_.Matches} | % {$_.Value}
$Currentversion = $Currentversion.Replace("Changes in ", "")
if ($Currentversion -gt $SFTPSrv){
    
    write-output "Update Available: $Currentversion `n Currently installed is $SFTPSrv `n Update details: http://dynamic.globalscape.com/support/history-eft.aspx"
    $exitcode = 1
}
Else {write-output "Server is currently up to date $SFTPSrv"
    $exitcode = 0
}
IF ($error -ne $null){
    write-output $error
$exitcode = 2
}
exit $exitcode
