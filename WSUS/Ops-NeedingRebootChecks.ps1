<# 
.PURPOSE
    Identifies computers that are online and needing a reboot to complete the patching process.

#> 

Function Process-OnlineNeedingReboots {
[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | out-null 
 
if (!$wsus) { 
        $wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer(); 
} 
 
$ComputerScope = new-object Microsoft.UpdateServices.Administration.ComputerTargetScope; 
$ComputerScope.IncludedInstallationStates = [Microsoft.UpdateServices.Administration.UpdateInstallationStates]::InstalledPendingReboot; 
 
$UpdateScope = new-object Microsoft.UpdateServices.Administration.UpdateScope; 
$UpdateScope.IncludedInstallationStates = [Microsoft.UpdateServices.Administration.UpdateInstallationStates]::InstalledPendingReboot; 
 
$TotalComputers = $wsus.GetComputerTargets($computerScope); 
$Script:MyArray = @()
$DeviceStatus = @()

foreach ($Device in $TotalComputers) {

    if (Test-Connection -BufferSize 32 -Count 1 -ComputerName $Device.FullDomainName -Quiet) {
        $DeviceStatus = 'Online'

        $OutputDeviceInformation = [PSCustomObject]@{    
            FullDomainName = $Device.FullDomainName
            OSDescription = $Device.OSDescription
            RequestedTargetGroupName = $Device.RequestedTargetGroupName
            DeviceStatus = $DeviceStatus
        }
        
        $Script:MyArray += $OutputDeviceInformation
    }

}

$TestPath = Test-Path 'C:\Scripts\WSUS\Compliance\Reboot Check Report\RebootCheckReport.html'

if (($Script:MyArray).count -eq 0) { exit }
if ($TestPath = "False") { $MyArray | ConvertTo-HTML > 'C:\Scripts\WSUS\Compliance\Reboot Check Report\RebootCheckReport.html' }
if ($TestPath = "True") {
    Remove-Item 'C:\Scripts\WSUS\Compliance\Reboot Check Report\RebootCheckReport.html'
    $Script:MyArray | ConvertTo-HTML > 'C:\Scripts\WSUS\Compliance\Reboot Check Report\RebootCheckReport.html'
}

}

Process-OnlineNeedingReboots

Function Email-Results {

$Output = $Script:MyArray | ConvertTo-HTML -Fragment

$body = @"
<html>  
  <body>
      <b><u>Instructions</b></u>
      <br />
      <br />
      Click on the attachment for a Web Help Desk friendly report.
      <br />
      <br />
      Step 1: View the RequestedTargetGroupName column. If it is a server object or you determine it should not be rebooted, speak with the designated owner.
      <br />
      Step 2: Remotely connect/view the computer and reboot to finish the patching process. Make sure someone is not actively using the device at the time.
      <br />
      <br />
      <b><u>Patched Computers Requiring Reboot</b></u>
      <br />
      <br />
        $Output
  </body>  
</html>  
"@

$params = @{ 
    Attachment = 'C:\Scripts\WSUS\Compliance\Reboot Check Report\RebootCheckReport.html'
    Body = $body 
    BodyAsHtml = $true
    Subject = "Twice Daily Patching Reboot Check Report"
    From = 'grc@test' 
    To = 'test@test'
    #Cc = 'test@test'
    SmtpServer = 'smtpserver'
    Port = 25
}
 
Send-MailMessage @params


}

Email-Results
