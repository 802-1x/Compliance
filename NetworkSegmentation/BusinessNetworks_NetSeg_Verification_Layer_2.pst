$Script:Networks = @(

    @{
        NetworkFriendlyName = "vID Name1"
        Subnet = Get-Subnet "x.x.x.x/23"
    }

    @{
        NetworkFriendlyName = "vID Name2"
        Subnet = Get-Subnet "x.x.x.x/26"
    }

)

Function Posture-Assessment($Network) {

Install-Module Subnet -Scope CurrentUser

$Gateway1 = $Network.Subnet.HostAddresses[0]
$Gateway2 = $Network.Subnet.HostAddresses[1]
$Gateway3 = $Network.Subnet.HostAddresses[2]
$HostRange = @()
foreach ($HostAddress in $Network.Subnet.HostAddresses) {
        if (($HostAddress –ne $Gateway1) -and ($HostAddress -ne $Gateway2) -and ($HostAddress -ne $Gateway3)) { $HostRange = $HostRange += $HostAddress }
    }
$Broadcast = $Network.Subnet.BroadcastAddress.IPAddressToString
$SubnetMatch = (($Network.Subnet.IPAddress.IPAddressToString).SubString(0,($Network.Subnet.IPAddress.IPAddressToString).Length-1)) + "*"

$NetworkFriendlyName = ($Network.NetworkFriendlyName).ToString()
$ExportPath = "\\server\share$\Network\NetworkSegmentationReports\$NetworkFriendlyName Results $(get-date -f yyyy-MM-dd).csv"

$Incrementer = 0
$Script:BodyData = ""

if (Test-Path "$ExportPath") { 
    Write-Host Removed old $NetworkFriendlyName CSV file -ForegroundColor Green
    Remove-Item "$ExportPath" }
else { Write-Host No existing $NetworkFriendlyName CSV file needs to be deleted -ForegroundColor Green }

# Saving time on the ping scan using task threading
Write-Host Ping sweep using task threading -ForegroundColor Yellow
$Tasks = $HostRange | % { [System.Net.NetworkInformation.Ping]::new().SendPingAsync($_) }; [Threading.Tasks.Task]::WaitAll($Tasks)
$SuccessfulPing = $Tasks.Result | where { $_.Status -eq 'Success' }
$ValidHosts = @()
foreach ($IP in $SuccessfulPing) { $ValidHosts = $ValidHosts += $IP.Address.IPAddressToString }

foreach ($IPAddress in $ValidHosts) {

    Write-Progress -Activity "Attempting to ping $IPAddress" -PercentComplete (($Incrementer++) / ($ValidHosts.count) * 100)

    if(Test-Connection -Cn $IPAddress -BufferSize 16 -Count 1 -ea 0 -quiet) {

        Try {
            Write-Host Attempting to DNS Lookup and then Invoke-Command against $IPAddress
            $Target = [System.Net.Dns]::GetHostByAddress("$IPAddress").HostName

            Try {
                #Initiate commands on target to determine compliance
                $Result = Invoke-Command -ComputerName $Target -ScriptBlock {
            
                    $SubnetMatch = $($args[0])
                    $Gateway1    = $($args[1])
                    $Gateway2    = $($args[2])
                    $Broadcast   = $($args[3])

                    $Return = Get-NetNeighbor -AddressFamily IPv4 | Where-Object {($_.IPAddress -like $SubnetMatch) -and ($_.IPAddress -ne $Gateway1) -and ($_.IPAddress -ne $Gateway2) -and ($_.IPAddress -ne $Broadcast)}
                    Return $Return

                    } -ArgumentList $SubnetMatch,$Gateway1,$Gateway2,$Broadcast -ErrorAction Stop
            
                if ($Result -eq $null){
                    Write-Host "$Target is correctly segmented!" -ForegroundColor DarkGreen -BackgroundColor White
                    }
                else {
                    $Script:BodyData += "`n"
                    $Script:BodyData += "$Target is incorrectly segmented!"
                    Write-Host "$Target is incorrectly segmented!" -ForegroundColor Red -BackgroundColor White
                    $Export = $Result | Select PSComputerName, IPAddress, LinkLayerAddress, State
                    $Export | Export-CSV "$ExportPath" -NoTypeInformation -Append
                   }
            }
            Catch {
                #$Script:BodyData += "`n"
                #$Script:BodyData += "$Target failed PowerShell Invoke Command. Windows 7? WinRM issue?"
                Write-Host "$Target failed PowerShell Invoke Command. Windows 7? WinRM issue?" -ForegroundColor White -BackgroundColor Red
            }
        }

        Catch {
            $Script:BodyData += "`n"
            $Script:BodyData += "$Target is incorrectly segmented!"
            Write-Host $IPAddress generated an error! Not a windows machine?  -ForegroundColor White -BackgroundColor Red

        }

    }
    
    #Invoke-Report $Network
    }
    
if (Test-Path "$ExportPath") {

    $Attachment = "$ExportPath"

$Body = @"
    This report checks communication between clients on a given VLAN. Compliant devices are not shown. Reports are not generated if fully compliant.

    Note ACLs are an example of what can fool this script. The assumption is that a vACL is configured correctly and therefore this tests for appropriate placements of vACLs in the network topology and port isolation.
    
    Connect to target computer and then run arp -a; then ping broadcast address; then run arp -a to validate results before and after a reboot.

    Detailed layer 2 reporting information can be found here: \\server\share$\Network\NetworkSegmentationReports

    $Script:BodyData
"@

$params = @{
    #Attachment = $Attachment
    Body = $Body
    Subject = "LAYER 2 ALERT: $NetworkFriendlyName Micro-segementation"
    From = 'grc@domain'
    To = '_NetworkNotifications@domain'
    #To = 'me@me'
    SmtpServer = 'smtp_fqdn'
    Port = 25
}

Send-MailMessage @params
Write-Host Sending $NetworkFriendlyName email report -ForegroundColor Green -BackgroundColor Blue

} else { Write-Host Success - no errors so no email report! -ForegroundColor Green -BackgroundColor Blue }
}

ForEach ($Network in $Script:Networks) {
    $NetworkFriendlyName = ($Network.NetworkFriendlyName).ToString()
    Write-Host Calculating $NetworkFriendlyName subnet details and counting dalmations -ForegroundColor Green
    Posture-Assessment $Network
}
