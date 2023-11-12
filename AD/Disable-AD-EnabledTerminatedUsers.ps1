<#
.SYNOPSIS 
    Identifies enabled users within a terminated users OU, disables those users, and then reports on actions taken.
	
.DESCRIPTION 
    AD query via PowerShell to disable enabled users in a designated OU. Sends email report on actions taken.
	
.NOTES 
	Author:		<redacted>
	Date:		October 4th 2022
	Notes:		Creation
#>

Import-Module ActiveDirectory
$OUpath = '<redacted>'

function Disable-TerminatedUsers {

$ADUsers = Get-ADUser -filter 'enabled -eq "true"' -Properties lastLogonDate, whencreated, description -SearchBase $OUPath

if (($ADUsers).count -eq '' ) { return; }

foreach ($User in $ADUsers) { Disable-ADAccount -Identity $User.SamAccountName }

if ( Test-Path -Path C:\Scripts\InfoSecCompliance\EnabledTerminatedUsers.csv ) { Remove-Item C:\Scripts\InfoSecCompliance\EnabledTerminatedUsers.csv }
$ADUsers | Export-CSV C:\Scripts\InfoSecCompliance\EnabledTerminatedUsers.csv -NoTypeInformation
$Attachment = "C:\Scripts\InfoSecCompliance\EnabledTerminatedUsers.csv"

$body = @"
<html>  
  <body>
      See attachment for log of enabled user accounts in the Terminated Users OU. This is a problem as accounts in this location are generally not monitored and do not necessarily have correct GPO user policies applied.<br><br>

      The accounts in the attached file have now been disabled.
  </body>  
</html>  
"@

$params = @{
    Attachment = $Attachment
    Body = $body 
    BodyAsHtml = $true
    Subject = "Disable Active Terminated User AD Account"
    From = '<redacted>' 
    To = '<redacted>'
    Cc = '<redacted>'
    SmtpServer = '<redacted>'
    Port = 25
}
 
Send-MailMessage @params

}

Disable-TerminatedUsers
