<#
.SYNOPSIS 
    Identifies all contractor AD accounts older than a year and disables the AD object.
	
.DESCRIPTION 
    SAP processes often fail here so this is a last failsafe to reduce our AD attack surface and keep AD objects down.
	
.NOTES 
	Author:		Me (me@domain)
	Date:		November 9th 2020
	Notes:		Creation
#>

function Disable-ADContractors {

$Date = (Get-Date).AddDays(-14)
$Date = Get-Date $Date -Format "MM/dd/yyyy HH:mm:ss"
$OUpath = 'OU1'
$2Weeks = (Get-Date).AddDays(-14)
$2Weeks = Get-Date $2Weeks -Format "MM/dd/yyyy HH:mm:ss"
$ADUsers = Get-ADUser -filter 'enabled -eq "true"' -Properties lastLogonDate, whencreated, description -SearchBase $OUPath | where {($_.lastlogondate -le "$Date")} | where {($_.lastlogondate -ne $null -and $_.whencreated -le "$2Weeks" -and $_.whenChanged -le "$2Weeks")}

if ( Test-Path -Path C:\Scripts\ADContractors.csv ) { Remove-Item C:\Scripts\ADContractors.csv }
$ADUsers | Export-CSV C:\Scripts\ADContractors.csv -NoTypeInformation
$Attachment = "C:\Scripts\ADContractors.csv"

if (($ADUsers).count -eq '' ) { return; }

foreach ($User in $ADUsers) { Disable-ADAccount -Identity $User.SamAccountName }

$body = @"
<html>  
  <body>
      See attachment for log of disabled accounts.
  </body>  
</html>  
"@

$params = @{
    Attachment = $Attachment
    #Body = $body 
    #BodyAsHtml = $true
    Subject = "Disable Inactive Contractor AD Account"
    From = 'grc@domain' 
    To = 'Person1@domain', 'Person2@domain'
    Cc = 'me@domain'
    SmtpServer = 'server'
    Port = 25
}
 
Send-MailMessage @params

}

Disable-ADContractors

function Disable-ADVendors {

$Date = (Get-Date).AddDays(-60)
$Date = Get-Date $Date -Format "MM/dd/yyyy HH:mm:ss"
$OUpath = 'OU2'
$2Weeks = (Get-Date).AddDays(-14)
$2Weeks = Get-Date $2Weeks -Format "MM/dd/yyyy HH:mm:ss"
$ADUsers = Get-ADUser -filter 'enabled -eq "true"' -Properties lastLogonDate, whencreated, description -SearchBase $OUPath | where {($_.lastlogondate -le "$Date")} | where {($_.lastlogondate -ne $null -and $_.whencreated -le "$2Weeks")}

if ( Test-Path -Path C:\Scripts\ADVendors.csv ) { Remove-Item C:\Scripts\ADVendors.csv }
$ADUsers | Export-CSV C:\Scripts\ADVendors.csv -NoTypeInformation
$Attachment = "C:\Scripts\ADVendors.csv"

if (($ADUsers).count -eq '' ) { return; }

foreach ($User in $ADUsers) { Disable-ADAccount -Identity $User.SamAccountName }

$body = @"
<html>  
  <body>
      See attachment for log of disabled accounts.
  </body>  
</html>  
"@

$params = @{ 
    Attachment = $Attachment
    #Body = $body 
    #BodyAsHtml = $true
    Subject = "Disable Inactive Vendor AD Accounts"
    From = 'grc@domain' 
    To = 'Person3@domain'
    Cc = 'me@domain'
    SmtpServer = 'server'
    Port = 25
}
 
Send-MailMessage @params

}

Disable-ADVendors

function Disable-Owners {

$Date = (Get-Date).AddDays(-60)
$Date = Get-Date $Date -Format "MM/dd/yyyy HH:mm:ss"
$OUpath = 'OU3'
$2Weeks = (Get-Date).AddDays(-14)
$2Weeks = Get-Date $2Weeks -Format "MM/dd/yyyy HH:mm:ss"
$ADUsers = Get-ADUser -filter 'enabled -eq "true"' -Properties lastLogonDate, whencreated, description -SearchBase $OUPath | where {($_.lastlogondate -le "$Date")} | where {($_.lastlogondate -ne $null -and $_.whencreated -le "$2Weeks")}

if ( Test-Path -Path C:\Scripts\ADOwners.csv ) { Remove-Item C:\Scripts\ADOwners.csv }
$ADUsers | Export-CSV C:\Scripts\ADOwners.csv -NoTypeInformation
$Attachment = "C:\Scripts\ADOwners.csv"

if (($ADUsers).count -eq '' ) { return; }

foreach ($User in $ADUsers) { Disable-ADAccount -Identity $User.SamAccountName }

$body = @"
<html>  
  <body>
      See attachment for log of disabled accounts.
  </body>  
</html>  
"@

$params = @{ 
    Attachment = $Attachment
    #Body = $body 
    #BodyAsHtml = $true
    Subject = "Disable Inactive Owners AD Accounts"
    From = 'grc@domain' 
    To = 'Person4@domain'
    Cc = 'me@domain'
    SmtpServer = 'server'
    Port = 25
}
 
Send-MailMessage @params

}

Disable-Owners

function Report-ADService {

$Date = (Get-Date).AddDays(-60)
$Date = Get-Date $Date -Format "MM/dd/yyyy HH:mm:ss"
$OUpath = 'OU4'
$2Weeks = (Get-Date).AddDays(-14)
$2Weeks = Get-Date $2Weeks -Format "MM/dd/yyyy HH:mm:ss"
$ADUsers = Get-ADUser -filter 'enabled -eq "true"' -Properties lastLogonDate, whencreated, description -SearchBase $OUPath | where {($_.lastlogondate -le "$Date")} | where {($_.lastlogondate -ne $null -and $_.whencreated -le "$2Weeks")}

if ( Test-Path -Path C:\Scripts\ADService.csv ) { Remove-Item C:\Scripts\ADService.csv }
$ADUsers | Export-CSV C:\Scripts\ADService.csv -NoTypeInformation
$Attachment = "C:\Scripts\ADService.csv"

if (($ADUsers).count -eq '' ) { return; }

#foreach ($User in $ADUsers) { Disable-ADAccount -Identity $User.SamAccountName }

$body = @"
<html>  
  <body>
      See attachment for log of inactive accounts.
  </body>  
</html>  
"@

$params = @{ 
    Attachment = $Attachment
    #Body = $body 
    #BodyAsHtml = $true
    Subject = "Report Inactive Service AD Account"
    From = 'grc@domain' 
    To = 'me@domain'
    SmtpServer = 'server'
    Port = 25
}
 
Send-MailMessage @params

}

Report-ADService

function Disable-ADExternal {

$Date = (Get-Date).AddDays(-60)
$Date = Get-Date $Date -Format "MM/dd/yyyy HH:mm:ss"
$OUpath = 'OU5'
$2Weeks = (Get-Date).AddDays(-14)
$2Weeks = Get-Date $2Weeks -Format "MM/dd/yyyy HH:mm:ss"
$ADUsers = Get-ADUser -filter 'enabled -eq "true"' -Properties lastLogonDate, whencreated, description -SearchBase $OUPath | where {($_.lastlogondate -le "$Date")} | where {($_.lastlogondate -ne $null -and $_.whencreated -le "$2Weeks")}

if ( Test-Path -Path C:\Scripts\ADExternal.csv ) { Remove-Item C:\Scripts\ADExternal.csv }
$ADUsers | Export-CSV C:\Scripts\ADExternal.csv -NoTypeInformation
$Attachment = "C:\Scripts\ADExternal.csv"

if (($ADUsers).count -eq '' ) { return; }

foreach ($User in $ADUsers) { Disable-ADAccount -Identity $User.SamAccountName }

$body = @"
<html>  
  <body>
      See attachment for log of inactive accounts.
  </body>  
</html>  
"@

$params = @{ 
    Attachment = $Attachment
    #Body = $body 
    #BodyAsHtml = $true
    Subject = "Disable Inactive External AD Account"
    From = 'grc@domain' 
    To = 'me@domain'
    SmtpServer = 'server'
    Port = 25
}
 
Send-MailMessage @params

}

Disable-ADExternal

function Report-ADProcessSystems {

$Date = (Get-Date).AddDays(-60)
$Date = Get-Date $Date -Format "MM/dd/yyyy HH:mm:ss"
$OUpath = 'OU6'
$2Weeks = (Get-Date).AddDays(-14)
$2Weeks = Get-Date $2Weeks -Format "MM/dd/yyyy HH:mm:ss"
$ADUsers = Get-ADUser -filter 'enabled -eq "true"' -Properties lastLogonDate, whencreated, description -SearchBase $OUPath | where {($_.lastlogondate -le "$Date")} | where {($_.lastlogondate -ne $null -and $_.whencreated -le "$2Weeks")}

if ( Test-Path -Path C:\Scripts\ADProcessSystems.csv ) { Remove-Item C:\Scripts\ADProcessSystems.csv }
$ADUsers | Export-CSV C:\Scripts\ADProcessSystems.csv -NoTypeInformation
$Attachment = "C:\Scripts\ADProcessSystems.csv"

if (($ADUsers).count -eq '' ) { return; }

#foreach ($User in $ADUsers) { Disable-ADAccount -Identity $User.SamAccountName }

$body = @"
<html>  
  <body>
      See attachment for log of inactive accounts.
  </body>  
</html>  
"@

$params = @{ 
    Attachment = $Attachment
    #Body = $body 
    #BodyAsHtml = $true
    Subject = "Report Inactive Process Systems AD Account"
    From = 'grc@domain' 
    To = 'me@domain'
    SmtpServer = 'server'
    Port = 25
}
 
Send-MailMessage @params

}

Report-ADProcessSystems
