Param
    (
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        
        [switch]$Print,
        [switch]$Serial
    )


$Credfile = ".\Windowscreds.xml"
$base = "vmware"

try
    {
    Add-PSSnapin VMware.VimAutomation.Core

    Get-VICredentialStoreItem -File $Credfile | %{
    $VIConnection = Connect-VIServer -Server $_.host -User $_.User -Password $_.Password}
    }
catch
    {
    Write-Error $_
    }


    #function Get-VMGuestStats {
# $a = Get-VM | ? {$_.PowerState -eq "PoweredON"} 
# $a| % { Write-Host $_ ; Get-Stat -Entity $_ -Realtime -MaxSamples 1 -stat * | Sort-Object -Property metricID | ft -AutoSize
# Get-VMGuestStats -vmserver $a -vcenter ($global:DefaultVIServer).Name -session ($global:DefaultVIServer).SessionSecret
Workflow Get-VMGuestStats {
    param(
        [string]$vcenter,
        [string[]]$vmserver,
        [string]$session,
        [Switch]$Print
    )
    foreach -parallel -ThrottleLimit 4 ($name in $vmserver){
      $vm = InlineScript  {
            Add-PSSnapin VMware.VimAutomation.Core

            $carbonServer = "192.168.1.54"
            $carbonServerPort = 2003

            function Send-ToGraphite {
                param(
                    [string]$carbonServer,
                    [string]$carbonServerPort,
                    [string[]]$metrics
                )
                    try
                    {
                    $socket = New-Object System.Net.Sockets.TCPClient 
                    $socket.connect($carbonServer, $carbonServerPort) 
                    $stream = $socket.GetStream() 
                    $writer = new-object System.IO.StreamWriter($stream)
                    foreach ($metric in $metrics){
                        #Write-Output $metric
                        $newMetric = $metric.TrimEnd()
                        #Write-Output $newMetric
                        $writer.WriteLine($newMetric)
                        }
                    $writer.Flush()
                    $writer.Close() 
                    $stream.Close()
                    }
                    catch
                    {
                        Write-Error $_
                    }
            }

            $WarningPreference = "SilentlyContinue";
            $elapsed = [System.Diagnostics.Stopwatch]::StartNew()
            (Connect-VIServer -Server $Using:vcenter -Session $Using:session) 2>&1 | out-null
            $WarningPreference = "Continue"; 
            "Total Elapsed Time Connecting: $($elapsed.Elapsed.ToString())"
            #$vmStats = Get-Stat -Entity $Using:name -Realtime -MaxSamples 1 -stat "*"
            $vmStats = Get-Stat -Entity $Using:name -IntervalSecs 1 -MaxSamples 3 -stat "*"
            $countvmMetrics = 0
            [string[]]$vmMetrics = @()
            $elapsed = [System.Diagnostics.Stopwatch]::StartNew()
            foreach($stat in $vmStats){
                    $time = $stat.Timestamp
                    $date = [int][double]::Parse((Get-Date (Get-Date $time).ToUniversalTime() -UFormat %s))
                    $metric = ($stat.MetricId).Replace(".latest","").split(".")
                    $value = $stat.Value
                    $unit = ($stat.Unit).Replace("%","Percent")
                    $instance = ($stat.instance).Split(".,/,_,:")[-1]
                    $vmName = $($Using:name).Replace(" ","-").Replace(".","-").Replace(")","").Replace("(","").ToLower()
                    if($instance -and $metric[0] -ne "sys"){
                     $result = "vmware.vm.$($vmName).$($metric[0])_$($metric[1]).$instance.$($metric[2])$unit $value $date"}
                    elseif($metric[0] -eq "sys" -and $instance){
                     $result = "vmware.vm.$($vmName).$($metric[0]).$($metric[1])_$($instance).$unit $value $date"}
                    else {
                     $result = "vmware.vm.$($vmName).$($metric[0])_$($metric[1]).$($metric[2])$unit $value $date"}
                     if($Using:Print){
                     Write-Output $result}
                     $vmMetrics += $result
                     $countvmMetrics = $countvmMetrics + 1
                   }
                  # Write-Output $vmMetrics
                #  "Total Elapsed Time getting metrics: $($elapsed.Elapsed.ToString())"
                 # Write-Output $vmMetrics.count
            Send-ToGraphite -carbonServer $carbonServer -carbonServerPort $carbonServerPort -metric $vmMetrics
           # Write-Output "-- VM Metrics      : $countvmMetrics"
             }
       # $vm
        }

   }

#}

#### Test SerialTime to Collect VMs

Add-PSSnapin VMware.VimAutomation.Core

            $carbonServer = "10.28.52.162"
            $carbonServerPort = 2003

            function Send-ToGraphite {
                param(
                    [string]$carbonServer,
                    [string]$carbonServerPort,
                    [string[]]$metrics
                )
                    try
                    {
                    $socket = New-Object System.Net.Sockets.TCPClient 
                    $socket.connect($carbonServer, $carbonServerPort) 
                    $stream = $socket.GetStream() 
                    $writer = new-object System.IO.StreamWriter($stream)
                    foreach ($metric in $metrics){
                        #Write-Output $metric
                        $newMetric = $metric.TrimEnd()
                        #Write-Output $newMetric
                        $writer.WriteLine($newMetric)
                        }
                    $writer.Flush()
                    $writer.Close() 
                    $stream.Close()
                    }
                    catch
                    {
                        Write-Error $_
                    }
            }


function Get-VMGuestStatsSerial {
  param(
        [Switch]$Print
    )
    $VMs = Get-VM | ? {$_.PowerState -eq "PoweredON"} 
        foreach ($vm in $VMs){
        $elapsed = [System.Diagnostics.Stopwatch]::StartNew()
            $vmStats = Get-Stat -Entity $vm -IntervalSecs 1 -MaxSamples 4 -stat "*"
            "Total Elapsed Time getting vmStats: $($elapsed.Elapsed.ToString())"
            $countvmMetrics = 0
            [string[]]$vmMetrics = @()
            foreach($stat in $vmStats){
                    $time = $stat.Timestamp
                    $date = [int][double]::Parse((Get-Date (Get-Date $time).ToUniversalTime() -UFormat %s))
                    $metric = ($stat.MetricId).Replace(".latest","").split(".")
                    $value = $stat.Value
                    $unit = ($stat.Unit).Replace("%","Percent")
                    $instance = ($stat.instance).Split(".,/,_,:")[-1]
                    $vmName = $($vm.Name).Replace(" ","-").Replace(".","-").Replace(")","").Replace("(","").ToLower()
                    if($instance -and $metric[0] -ne "sys"){
                     $result = "vmware.vm.$($vmName).$($metric[0])_$($metric[1]).$instance.$($metric[2])$unit $value $date"}
                    elseif($metric[0] -eq "sys" -and $instance){
                     $result = "vmware.vm.$($vmName).$($metric[0]).$($metric[1])_$($instance).$unit $value $date"}
                    else {
                     $result = "vmware.vm.$($vmName).$($metric[0])_$($metric[1]).$($metric[2])$unit $value $date"}
                     if($Print){
                     Write-Output $result}
                     $vmMetrics += $result
                     $countvmMetrics = $countvmMetrics + 1
                   }
                "Total Elapsed Time converting metrics: $($elapsed.Elapsed.ToString())"
                Send-ToGraphite -carbonServer $carbonServer -carbonServerPort $carbonServerPort -metric $vmMetrics
                "Total Elapsed Time all: $($elapsed.Elapsed.ToString())"
                Write-Output "-- VM Metrics      : $countvmMetrics"
    }

}



#######
#Start Jobs
while ($true)
{



if($Serial){
    #Run Serial fetch
    if ((get-date) -ge $nextVMRun){
        $nextVMRun = (get-date -second 00).AddMinutes(1)
        $elapsed = [System.Diagnostics.Stopwatch]::StartNew()
            if($Print){
                        Get-VMGuestStatsSerial -Print
                    }
                else {Get-VMGuestStatsSerial}
        "Total Elapsed Time VM Guests: $($elapsed.Elapsed.ToString())"
        $VMHostTimeDiff = NEW-TIMESPAN –Start (get-date) –End $nextVMRun
        }
    }
    else {
    #VM Metrics (20 seconds apart)
    #get VMs
    if ((get-date) -ge $nextVMRun)
    {
        $nextVMRun = (get-date -second 00).AddMinutes(1)
        $elapsed = [System.Diagnostics.Stopwatch]::StartNew()
        $VMs = Get-VM | ? {$_.PowerState -eq "PoweredON"} 
            if($Print){
                        Get-VMGuestStats -vmserver $VMs -vcenter ($global:DefaultVIServer).Name -session ($global:DefaultVIServer).SessionSecret -Print
                    }
                else {Get-VMGuestStats -vmserver $VMs -vcenter ($global:DefaultVIServer).Name -session ($global:DefaultVIServer).SessionSecret}

        "Total Elapsed Time VM Guests: $($elapsed.Elapsed.ToString())"
        $VMHostTimeDiff = NEW-TIMESPAN –Start (get-date) –End $nextVMRun
     #   Write-Output "Metric receive at: $global:VMHostMetricTime -- $nextVMHostRun -- $VMHostTimeDiff -- Next collection in $($VMHostTimeDiff.TotalSeconds) seconds"
    }
}
    if ([int]$($VMHostTimeDiff.TotalSeconds) -le 0) {}
    else {
        Write-Output "Sleeping $($VMHostTimeDiff.TotalSeconds) seconds"
        sleep $($VMHostTimeDiff.TotalSeconds)
    }
    $VMHostTimeDiff = 0
}