#Export CSV of host IP data for SnipeIT
Import-Module SimplySql
Import-Module PSHTML
#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#Install-Module SnipeitPS -Proxy 'http://x.x.x.x:8080'
#Import-Module SnipeitPS
Set-Info -URL 'https://server' -apiKey ''
$URL    = 'https://tacasset'
$apiKey = ''

$currentPeriod = Get-Date -Format 'dd/MM/yyyy 00:00:00'
$currentTime   = Get-Date

##### Get the network info
$ndUser    = "user"
Open-PostGreConnection -Server netdisco -Database netdisco -UserName $ndUser -Password password #needs updating to secure method

# Get todays devices
$recentDevices = Invoke-SqlQuery "SELECT * FROM node WHERE time_first > '$currentPeriod' AND vlan != 'x'"
$recentDevices = $recentDevices | Sort-Object -Unique -Property mac

# Filter for devices we haven't seen before, that aren't on vlan x
$unknownDevices=@()
foreach($device in $recentDevices){
    $findMAC      = $device.mac
    $findSwitch   = $device.switch
    # Are there older entries for this device in netdisco?
    $checkPrevious = Invoke-SqlQuery "SELECT * FROM node WHERE mac = '$findmac' AND time_first < '$currentPeriod '"
    # If not, check if we've already logged this device
    if($null -eq $checkPrevious){
        $checkLogTable = Invoke-DbaQuery -SqlInstance "server.fqdn" -Database db -Query "SELECT * FROM dbo.netdiscoNewDevices WHERE MAC = '$findmac'"
    }
    # If we haven't seen it before, or logged it yet - get some more info, and put it in the log
    if($null -eq $checkLogTable -and $null -eq $checkPrevious){
        $getDNS    = Invoke-SqlQuery "SELECT dns FROM node_ip WHERE mac = '$findMAC'"
        $assetName = $getDNS.dns.Split("{.}")[0]
        $findKnownAsset = Get-Asset $assetName
        if([String]::IsNullOrWhiteSpace($null -ne $assetName) -eq $true){
            if($null -ne $findKnownAsset){$assetRecord = "yes"} else {$assetRecord = "no"}
            $getSwitch = Invoke-SqlQuery "SELECT name FROM device WHERE ip = '$findSwitch'"    
            $getIP     = Invoke-SqlQuery "SELECT ip from node_ip WHERE mac = '$findMAC'"  
            $unknownDevices += [PSCustomObject]@{
                DNS        = $getDNS.dns;    
                MAC        = $device.mac;
                IP         = $getIP.ip;
                Switch     = $getswitch.name;
                SwitchIP   = $device.switch;
                Port       = $device.port;
                Vlan       = $device.vlan;
                TimeFirst  = $device.time_first;     
                UpdateTime = $currentTime;
                KnownAsset = $assetRecord;}    
            }
}}
Close-SqlConnection
Write-DbaDataTable -SqlInstance "server.fqdn" -Database db -Table dbo.netdiscoNewDevices -InputObject $unknownDevices

# filter netdisco results for row with most info
# sql table is report list
# lookup mac in SnipeIT to determine if device is known - problem tiny pc's with wifi show 2 macs
# get most recent ip for the device
