$Script:Networks = @(

    @{
        NetworkFriendlyName = "vID Name1"
        Subnet = Get-Subnet "x.x.x.x/24"
    }

    @{
        NetworkFriendlyName = "vID Name2"
        Subnet = Get-Subnet "x.x.x.x/26"
    }
)

Function Posture-Assessment($Network) {

Install-Module Subnet -Scope CurrentUser -Force

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
$Tasks = $HostRange | % { [System.Net.NetworkInformation.Ping]::new().SendPingAsync($_) }; [Threading.Tasks.Task]::WaitAll($Tasks)
$SuccessfulPing = $Tasks.Result | where { $_.Status -eq 'Success' }
$ValidHosts = @()
foreach ($IP in $SuccessfulPing) { $ValidHosts = $ValidHosts += $IP.Address.IPAddressToString }

# Connections to host and subsequent validation
foreach ($IPAddress in $ValidHosts) {

    Write-Progress -Activity "Attempting to ping $IPAddress" -PercentComplete (($Incrementer++) / ($ValidHosts.count) * 100)

    if(Test-Connection -Cn $IPAddress -BufferSize 16 -Count 1 -ea 0 -quiet) {

        Try {
            Write-Host Attempting to DNS Lookup and then Invoke-Command against $IPAddress
            $Target = [System.Net.Dns]::GetHostByAddress("$IPAddress").HostName

            Try {
                #Initiate commands on target to determine compliance
                [Array]$ModValidHosts = $ValidHosts.Split(" ") -ne $IPAddress

                $Result = Invoke-Command -ComputerName $Target -ScriptBlock {
            
                    $ModValidHosts   = $($args[0])
                    $Return =@()

                    $Tasks = $ModValidHosts | % { [System.Net.NetworkInformation.Ping]::new().SendPingAsync($_) }; [Threading.Tasks.Task]::WaitAll($Tasks)
                    $SuccessfulPing = $Tasks.Result | where { $_.Status -eq 'Success' }
                    foreach ($IP in $SuccessfulPing) { $Return = $ModValidHosts += $IP.Address.IPAddressToString }
                    Return $Return

                    } -ArgumentList $ModValidHosts -ErrorAction Stop
            
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

    This script accomplishes validation via ping sweeps to test layer 3 segmentation. Note ACLs are an example of what can fool this script. The assumption is that a vACL is configured correctly and therefore this tests for appropriate placements of vACLs in the network topology and port isolation.
    
    If exceptions occur, these can be remediated with either port isolation or appropriate placement of vACLs.

    $Script:BodyData
"@

$params = @{
    #Attachment = $Attachment
    Body = $Body
    Subject = "LAYER 3 ALERT: $NetworkFriendlyName Micro-segementation"
    From = 'email@email'
    To = 'email@email'
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
