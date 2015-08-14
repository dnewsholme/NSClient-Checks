function Get-ADReplicationstatus{
 $workfile = repadmin.exe /showrepl * /csv 
 $results = ConvertFrom-Csv -InputObject $workfile
 Return $results
}

$output = Get-ADReplicationstatus | where {$_.'Number of Failures' -gt 0}

if ($output)
{
    $output | ft
    $nagiosexitcode = 2
}
Else {
    "No Replication issues"
    $nagiosexitcode = 0
}
exit $nagiosexitcode
