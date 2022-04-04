<# 
.SYNOPSIS 
    As per Microsoft's best practice, this script runs the WSUS Cleanup Wizard on a weekly basis so as to keep the number of unneeded updates and revisions to a minimum..
	
.DESCRIPTION 
    Loads the WSUS API, configures the relevant switches, and then runs the Cleanup Wizard.
#> 

# WSUS Connection Parameters:
[String]$updateServer = "updateserver"
[Boolean]$useSecureConnection = $False
[Int32]$portNumber = 8530
 
# Cleanup Parameters:
# Decline updates that have not been approved for 30 days or more, are not currently needed by any clients, and are superseded by an aproved update.
[Boolean]$supersededUpdates = $True
# Decline updates that aren't approved and have been expired my Microsoft.
[Boolean]$expiredUpdates = $True
# Delete updates that are expired and have not been approved for 30 days or more.
[Boolean]$obsoleteUpdates = $True
# Delete older update revisions that have not been approved for 30 days or more.
[Boolean]$compressUpdates = $True
# Delete computers that have not contacted the server in 30 days or more.
[Boolean]$obsoleteComputers = $False
# Delete update files that aren't needed by updates or downstream servers.
[Boolean]$unneededContentFiles = $True

# Load .NET assembly
[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
 
# Connect to WSUS Server
$Wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($updateServer,$useSecureConnection,$portNumber)

#...................................
# Processes
#................................... 

# Deny all superceded updates
Get-WSUSUpdate -Classification All -Status Any -Approval AnyExceptDeclined `
    | Where-Object { $_.Update.GetRelatedUpdates(([Microsoft.UpdateServices.Administration.UpdateRelationship]::UpdatesThatSupersedeThisUpdate)).Count -gt 0 } `
    | Deny-WsusUpdate

# Run clean up of updates in database
$CleanupManager = $Wsus.GetCleanupManager()
$CleanupScope = New-Object Microsoft.UpdateServices.Administration.CleanupScope($supersededUpdates,$expiredUpdates,$obsoleteUpdates,$compressUpdates,$obsoleteComputers,$unneededContentFiles)
$Result = $CleanupManager.PerformCleanup($CleanupScope) | Out-String

# Email results of cleanup
Send-MailMessage -To "test@test" -Subject "Started New Cycle and Clean Up Confirmation" -Body "$Result" -SMTPServer "server" -From "WSUSReporting@test" 
