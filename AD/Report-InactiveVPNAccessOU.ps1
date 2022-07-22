function Report-InactiveVPNAccessOU {

$OUpath = 'OU'
$ReportPeriod = Get-Date ((Get-Date).AddDays(-61)) -Format "MM/dd/yyyy HH:mm:ss"
$ActiveADUsers = Get-ADUser -filter 'enabled -eq "true"' -Properties lastLogonDate, whencreated, AccountExpirationDate, PasswordNeverExpires, description -SearchBase $OUPath | where {($_.lastlogondate -ge $ReportPeriod)} | where {($_.whencreated -le "$ReportPeriod" -or $_.whenChanged -le "$ReportPeriod")} | Select Name, SamAccountName, Description, whencreated, LastLogonDate, AccountExpirationDate, PasswordNeverExpires
$StaleADUsers = Get-ADUser -filter 'enabled -eq "true"' -Properties lastLogonDate, whencreated, AccountExpirationDate, PasswordNeverExpires, description -SearchBase $OUPath | where {($_.lastlogondate -le $ReportPeriod)} | where {($_.whencreated -le "$ReportPeriod" -or $_.whenChanged -le "$ReportPeriod")} | Select Name, SamAccountName, Description, whencreated, LastLogonDate, AccountExpirationDate, PasswordNeverExpires

if ( Test-Path -Path C:\Scripts\InfoSecCompliance\ActiveADVPNAccessOU.csv ) { Remove-Item C:\Scripts\InfoSecCompliance\ActiveADVPNAccessOU.csv }
$ActiveADUsers | Export-CSV C:\Scripts\InfoSecCompliance\ActiveADVPNAccessOU.csv -NoTypeInformation
if ( Test-Path -Path C:\Scripts\InfoSecCompliance\StaleADVPNAccessOU.csv ) { Remove-Item C:\Scripts\InfoSecCompliance\StaleADVPNAccessOU.csv }
$StaleADUsers | Export-CSV C:\Scripts\InfoSecCompliance\StaleADVPNAccessOU.csv -NoTypeInformation

$Attachment = "C:\Scripts\InfoSecCompliance\ActiveADVPNAccessOU.csv", "C:\Scripts\InfoSecCompliance\StaleADVPNAccessOU.csv"

if (($ActiveADUsers).count -eq '' -or ($StaleADUsers).count -eq '') { return; }

$body = @"
<html>  
  <body>
      See attachment for log of inactive accounts. Included are active accounts for current planning purposes.
  </body>  
</html>  
"@

$params = @{
    Attachment = $Attachment
    Body = $body 
    BodyAsHtml = $true
    Subject = "Inactive VPNAccess OU AD Account"
    From = 'grc@email' 
    To = 'me@email'#, 'Person2@domain'
    #Cc = 'me@domain'
    SmtpServer = 'server'
    Port = 25
}
 
Send-MailMessage @params

}

Report-InactiveVPNAccessOU
