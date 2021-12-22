#Check Netdisco for previously undetected devices, check if they are present in SnipeIT, then put into SQL
Import-Module SimplySql
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module SnipeitPS -Proxy 'http://x.x.x.x:8080'
Import-Module SnipeitPS
Set-Info -URL 'https://server' -apiKey ''

$currentPeriod = Get-Date -Format 'yyyy-MM-dd 00:00:00'
$currentTime   = Get-Date

##### Get the network info
$ndUser    = "user"
$encrypted = Get-Content 'C:\folder\cred\ndcred.txt'| ConvertTo-SecureString
Open-PostGreConnection -Server netdisco -Database netdisco -UserName $ndUser -Password $encrypted

# Get todays devices
$recentDevices = Invoke-SqlQuery "SELECT * FROM node WHERE time_first > '$currentPeriod' AND vlan != '105'"
$recentDevices = $recentDevices | Sort-Object -Unique -Property mac

# Filter for devices we haven't seen before, that aren't on vlan x
$unknownDevices=@()
foreach($device in $recentDevices){
    $findMAC      = $device.mac
    $findSwitch   = $device.switch
    $checkPrevious = Invoke-SqlQuery "SELECT * FROM node WHERE mac = '$findmac' AND time_first < '$currentPeriod '"
    if($null -eq $checkPrevious){
        $checkLogTable = Invoke-DbaQuery -SqlInstance "server.fqdn" -Database Sophos -Query "SELECT * FROM dbo.netdiscoNewDevices WHERE MAC = '$findmac'"
    }
    if($null -eq $checkLogTable -and $null -eq $checkPrevious){
        $getDNS    = Invoke-SqlQuery "SELECT dns FROM node_ip WHERE mac = '$findMAC'"
        $getIP     = Invoke-SqlQuery "SELECT ip FROM node_ip WHERE mac = '$findMAC' AND dns IS NOT NULL"
        if([String]::IsNullOrWhiteSpace($getDNS.dns) -eq $false){
            
            $assetName = $getDNS.dns.Split("{.}")[0]
            $findKnownAsset = Get-Asset $assetName
            if($null -ne $findKnownAsset){$assetRecord = "yes"} else {$assetRecord = "no"}
            $getSwitch = Invoke-SqlQuery "SELECT name FROM device WHERE ip = '$findSwitch'"
            $desc = Get-ADComputer $assetName -Properties Description
            
            $unknownDevices += [PSCustomObject]@{
                DNS         = $getDNS.dns;
                Description = $desc.Description;   
                MAC         = $device.mac;
                IP          = $getIP.ip.IPAddressToString;
                Switch      = $getswitch.name;
                SwitchIP    = $device.switch;
                Port        = $device.port;
                Vlan        = $device.vlan;
                TimeFirst   = $device.time_first;     
                UpdateTime  = $currentTime;
                KnownAsset  = $assetRecord;}    
            }
        }
    }
Close-SqlConnection
Write-DbaDataTable -SqlInstance "server.fqdn" -Database name -Table dbo.netdiscoNewDevices -InputObject $unknownDevices
