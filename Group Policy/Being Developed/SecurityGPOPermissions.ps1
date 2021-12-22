Import-Module ActiveDirectory

$AllGPOs = Get-GPO -All -Domain "domain"
$AllGPOs[0].DisplayName

foreach ($GPO in $AllGPOs) {

    $GPOPermissions = Get-GPPermission -Name $GPO.DisplayName -All
    
    foreach ($Permission in $GPOPermissions) {
        if ($Permission.Trustee.SidType -eq 'User') {
            $Output += $GPO.DisplayName
            #$Permission.Trustee
        }
    }
}

#$GPO = Get-GPPermission -Name WSUS-CaptureStragglers -All

<#

$AllGPOs = Get-GPO -All -Domain "domain"
$AllGPOs[0].DisplayName

foreach ($GPO in $AllGPOs) {

    if ($GPO.Owner -ne 'netbios\Domain Admins') {
        Write-Host $GPO.Owner
    }
}#>


$Body = @"
<html>  
    <body>
    This script needs improvement. Placeholder so the work is not forgotten. Script is on server.
    <br />
    <br />
    $Output
    </body>  
</html>  
"@

$params = @{ 
    Body = $body 
    BodyAsHtml = $true 
    Subject = "Group Policy Permission Rectifications" 
    From = 'grc@domain'
    To = 'me@domain', 'Person1@domain'
    SmtpServer = 'server'
    Port = 25
}

Send-MailMessage @params
