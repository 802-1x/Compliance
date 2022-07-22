function Report-DangerousAttributesVPNAccessOU {

$OUpath = 'OU'
$PwdNeverExpires = Get-ADUser -filter 'enabled -eq "true"' -Properties Name, PasswordNeverExpires, Description -SearchBase $OUPath | where { $_.PasswordNeverExpires -eq "true" } |  Select Name, PasswordNeverExpires, Description
$NonMFAUsers = @()
#Remove-Variable Output
#Remove-Variable OutputInformation

$Users = Get-ADUser -filter * -SearchBase $OUPath
$GroupMembers = Get-ADGroupMember -Identity "GroupName" -Recursive | Select Name

foreach ($User in $Users) {
    
    if ($GroupMembers.Name -Contains $User.Name) {
        
        $OutputInformation = [PSCustomObject]@{ Name = $User.Name }
        $NonMFAUsers += $OutputInformation.Name
}
}

if ( Test-Path -Path C:\Scripts\InfoSecCompliance\PwdNeverExpires.csv ) { Remove-Item C:\Scripts\InfoSecCompliance\PwdNeverExpires.csv }
$PwdNeverExpires | Export-CSV C:\Scripts\InfoSecCompliance\PwdNeverExpires.csv -NoTypeInformation

if ( Test-Path -Path C:\Scripts\InfoSecCompliance\NonMFAUsers.csv ) { Remove-Item C:\Scripts\InfoSecCompliance\NonMFAUsers.csv }
$NonMFAUsers | Out-File C:\Scripts\InfoSecCompliance\NonMFAUsers.csv #-NoTypeInformation

$Attachment = "C:\Scripts\InfoSecCompliance\PwdNeverExpires.csv", "C:\Scripts\InfoSecCompliance\NonMFAUsers.csv"

if (($PwdNeverExpires).count -eq '' -and ($NonMFAUsers).count -eq '') { return; }

$PwdNeverExpireCount = ($PwdNeverExpires).count
$NonMFACount = ($NonMFAUsers).count

$body = @"
<html>  
  <body>
      See attached logs for "password never expires" attribute and accounts without MFA requirement.<br><br>

      Password never expires count: $PwdNeverExpireCount  <br>
      Non-MFA users: $NonMFACount
  </body>  
</html>  
"@

$params = @{
    Attachment = $Attachment
    Body = $body 
    BodyAsHtml = $true
    Subject = "Vendor Account Dangerous Attributes and non-MFA"
    From = 'grc@email' 
    To = 'me@email'#, 'Person2@domain'
    #Cc = 'me@domain'
    SmtpServer = 'server'
    Port = 25
}
 
Send-MailMessage @params

}

Report-DangerousAttributesVPNAccessOU
