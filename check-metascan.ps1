<#

.SYNOPSIS
Queries the specified metascan server and retrieves operational statistics

.DESCRIPTION
Queries the specified metascan server and retrieves operational statistics

.EXAMPLE
Get-MetascanStatstics -Computername "671630-lteitg04" -checkperiod 1

.NOTES


#>
function Get-MetascanStatstics{
    param (
        [String]$Computername = $env:COMPUTERNAME,
        $CheckPeriod=1
        )

    $unknown = 3
    $critical = 2
    $warning = 1
    $ok = 0

    #MetaScan Rest API
    $statusapi = "http://" + $Computername + ":8008/metascan_rest/status"
    $scanhistoryapi = "http://" + $Computername + ":8008/metascan_rest/stat/scanhistory/$CheckPeriod"
    $fileuploadapi = "http://" + $Computername + ":8008/metascan_rest/stat/fileuploads/$CheckPeriod"
    $queueapi = "http://" + $Computername + ":8008/metascan_rest/file/inqueue"

    #Query the rest interface
    $statusresult = invoke-restmethod $statusapi -method get -timeoutsec 5
    $scanhistoryresult = invoke-restmethod $scanhistoryapi -method get -timeoutsec 5
    $fileuploadresult = invoke-restmethod $fileuploadapi -method get -timeoutsec 5
    $queueresult = invoke-restmethod $queueapi -method get -timeoutsec 5

    
    
    if (!($statusresult)){
        $result = "Could not connect to rest api"
        $nagiosexitcode = $critical
    }
    Else{
        #Calculate totals for check CheckPeriod
        $scanhistoryresult.total_scanned_files | %{$totalscan +=$_}
        $scanhistoryresult.total_infected | %{$totalinfect +=$_}
        $scanhistoryresult.avg_scan_time | %{$totalavgscan +=$_}
        if($totalavgscan -gt 0)
        {$totalavgscan = ($totalavgscan / ($scanhistoryresult.avg_scan_time | ? {$_ -ne 0}).count)}
        $totalavgscan = [math]::Round($totalavgscan)
   
        $nagiosexitcode = 0
        $result = New-Object psobject
        $result | Add-Member -MemberType NoteProperty -Name 'Metascan Server Running Since' -Value $statusresult.server_started
        $result | Add-Member -MemberType NoteProperty -Name 'Version' -Value $statusresult.metascan_ver
        $result | Add-Member -MemberType NoteProperty -Name "Files scanned" -Value $totalscan
        $result | Add-Member -MemberType NoteProperty -Name "Infected files" -Value $totalinfect
        $result | Add-Member -MemberType NoteProperty -Name "Average scan time" -Value $totalavgscan
        $result | Add-Member -MemberType NoteProperty -Name "Total number of items in queue" -Value $queueresult.in_queue
        $result | Add-Member -MemberType NoteProperty -Name "Nagiosexitcode" -Value $nagiosexitcode
        }
return $result
}

$result = get-metascanstatstics
$textoutput = " Metascan Server Running since: {0} `n Version: {1} `n Files scanned: {2} `n Infected files: {3} `n Average scan time: {4} `n Total Number of items in queue: {5}" -f $result.'Metascan Server Running Since', $result.'Version', $result.'Files scanned',$result.'Infected files',$result.'Average scan time', $result.'Total number of items in queue'
$perfdata = "FilesScanned={0}, InfectedFiles={1}, AverageScantimeMs={2}, QueueSize={3}" -f $result.'Files scanned',$result.'Infected files',$result.'Average scan time', $result.'Total number of items in queue'
$nagiosresult = "$textoutput | $perfdata"
$nagiosresult
if($Error){$nagiosexitcode = $critical}
exit $result.Nagiosexitcode
