Import-Module ActiveDirectory

Remove-Variable Output
Remove-Variable OutputInformation
$Output = @()
$PreviousWeek = (Get-date).AddDays(-7)

$AccountsOfInterest = Get-ADUser -Filter * -Property Name, BadLogonCount, Enabled, lockoutTime, LastBadPasswordAttempt, whenChanged | Where-Object {$_.Enabled -like “false” -and $_.BadLogonCount -gt 0 -and $_.LastBadPasswordAttempt -gt $_.whenChanged } | Select Name, Enabled, BadLogonCount, LockedOut, LastBadPasswordAttempt, whenChanged | sort LastBadPasswordAttempt -descending
#($AccountsOfInterest).count
$AccountsOfInterest = $AccountsOfInterest | where { $_.LastBadPasswordAttempt -ge $PreviousWeek }

foreach ($User in $AccountsOfInterest) {

    $OutputInformation = [PSCustomObject]@{    
        Name = $User.Name
        Enabled = $User.Enabled
        BadLogonCount = $User.BadLogonCount
        LockedOut = $User.LockedOut
        LastBadPasswordAttempt = $User.LastBadPasswordAttempt
        whenChanged = $User.whenChanged
    }
    $Output += $OutputInformation

}

$Output = $Output | ConvertTo-HTML -Fragment


$body = @"
<html>  
  <body>
      Data sorted by LastBadPasswordAttempt attribute. Data will only appear if LastBadPasswordAttempt date greater than whenChanged attribute date and BadLogonCount greater than 0 value.<br><br>

      Line items can be cleared by going into Active Directory and using the 'Unlock account' tickbox under the Accounts tab, which will reset BadLogonCount back to 0 value.<br><br>

      For recent entries, use Tenable.ad to cross reference Indicators of Attack data sources and Trail Flow for determining source IPs. Failing these two options, check Event Viewer on the Domain Controllers for event ID 4625.<br><br>

      $Output
  </body>
</html>
"@

$params = @{
    Body = $Body
    BodyAsHtml = $true
    Subject = "Failed Logon Attempts on Disabled Accounts"
    From = 'grc@domain'
    To = 'group@domain'
    #To = 'me@domain'
    SmtpServer = 'SMTP_FQDN'
    Port = 25
}

Send-MailMessage @params
