Import-Module ActiveDirectory
Import-Module dbatools

##updated $adserver to exclude the "Remove OU" under Server-Resources

$ServerExceptions = 'Server1','Server2'
$WorkstationExceptions = 'Workstation1','Workstation2'

<#Import data that has been manually downloaded via CSV from Sophos Central for testing
$ServerList = (Import-CSV "C:\Downloads\servers.csv") | Select "Name"
$WorkstationList = (Import-CSV "C:\Downloads\computers.csv") | Select "Name"#>

$ServerList = Invoke-DbaQuery           -SqlInstance "server.domain" -Database Sophos -Query "SELECT * FROM dbo.CentralReport WHERE Type = 'Server';"
$WorkstationList = Invoke-DbaQuery      -SqlInstance "server.domain" -Database Sophos -Query "SELECT * FROM dbo.CentralReport WHERE Type = 'Workstation';"

#Create reference object lists
$ADServers = Get-ADComputer -Filter { OperatingSystem -Like '*Windows Server*' -and Enabled -eq $True} |
        Where-Object { ($_.DistinguishedName -notlike '*OU=Computers For Deletion,OU') -or ($_.DistinguishedName -notlike '*OU=Remove,OU') } |
        Select Name

$ADWorkstations = Get-ADComputer -Filter { OperatingSystem -NotLike '*Windows Server*' -and Enabled -eq $True} -Properties DistinguishedName |
    Where-Object { $_.DistinguishedName -notlike '*OU=Computers For Deletion,OU' } |
    Where-Object { $_.DistinguishedName -notlike '*CN=Computers,DC=' } |
    Where-Object { $_.DistinguishedName -notlike '*OU' } |
    Select Name

#UnprotectedDevices

#Create difference object lists
$MissingServers = Compare-Object -ReferenceObject $ADServers.name -DifferenceObject $ServerList."Name" |
    Where-Object { $_.SideIndicator -eq '<=' } | #We do not want devices that have been decommissioned from AD but have not been deleted from Sophos Central
    ForEach-Object { $_.InputObject } |
    Where-Object { $ServerExceptions -notcontains $_ } | #Remove load balanced names etc
    Sort

$MissingWorkstations = Compare-Object -ReferenceObject $ADWorkstations.name -DifferenceObject $WorkstationList.Name |
    Where-Object { $_.SideIndicator -eq '<=' } | #We do not want devices that have been decommissioned from AD but have not been deleted from Sophos Central
    ForEach-Object { $_.InputObject } |
    Where-Object { $WorkstationExceptions -notcontains $_ } | #Remove load balanced names etc
    Sort

<#foreach ($Device in $MissingServers) {

    Get-ADComputer $Device -Properties Description | Select Name, DistinguishedName, Description

}

foreach ($Device in $MissingWorkstations) {

    Get-ADComputer $Device -Properties Description | Select Name, DistinguishedName, Description

}#>


#InactiveCentralObjects
<#
$InactiveServerExceptions = 'Server1','Server2'
$InactiveWorkstationExceptions = @{}

$InactiveADWorkstations = Get-ADComputer -Filter { OperatingSystem -NotLike '*Windows Server*' -and Enabled -eq $True} -Properties DistinguishedName |
    Select Name

#Create difference object lists
$InactiveServers = Compare-Object -ReferenceObject $ADServers.name -DifferenceObject $ServerList."Name" |
    Where-Object { $_.SideIndicator -eq '=>' } | #We do not want devices that have been decommissioned from AD but have not been deleted from Sophos Central
    ForEach-Object { $_.InputObject } |
    Where-Object { $InactiveServerExceptions -notcontains $_ } | #Remove load balanced names etc
    Sort

$InactiveWorkstations = Compare-Object -ReferenceObject $InactiveADWorkstations.name -DifferenceObject $WorkstationList.Name |
    Where-Object { $_.SideIndicator -eq '=>' } | #We do not want devices that have been decommissioned from AD but have not been deleted from Sophos Central
    ForEach-Object { $_.InputObject } |
    Where-Object { $InactiveWorkstationExceptions -notcontains $_ } | #Remove load balanced names etc
    Sort
    #>

#Email reports

function EmailMissingServers {

$Output = @()

foreach ($Device in $MissingServers) {

    $OutputDeviceInformation = [PSCustomObject]@{    
        Device = $Device
    }
    $Output += $OutputDeviceInformation

}

$Output = $Output | ConvertTo-HTML -Fragment

$body = @"
<html>  
  <body>
      $Output
  </body>  
</html>  
"@

$params = @{ 
    #Attachment = $Path1, $Path2
    Body = $body 
    BodyAsHtml = $true
    Subject = "Sophos AD Missing Server Installs"
    From = 'grc@domain' 
    To = 'group@domain'
	  #To = 'me@domain'
    #Cc = 'grc@domain'
    SmtpServer = 'server'
    Port = 25
}
 
Send-MailMessage @params

}

if ($MissingServers -ne $null) { EmailMissingServers } 

function EmailMissingWorkstations {

$Output = @()

foreach ($Device in $MissingWorkstations) {

    $OutputDeviceInformation = [PSCustomObject]@{    
        FullDomainName = $Device
    }
    $Output += $OutputDeviceInformation

}

$Output = $Output | ConvertTo-HTML -Fragment

$body = @"
<html>  
  <body>
      $Output
  </body>  
</html>  
"@

$params = @{ 
    Body = $body 
    BodyAsHtml = $true
    Subject = "Sophos AD Missing Workstations Installs"
    From = 'grc@domain' 
    To = 'helpdesk@domain'
    Cc = 'me@domain'
    SmtpServer = 'server'
    Port = 25
}
 
Send-MailMessage @params

}

if ($MissingWorkstations -ne $null) { EmailMissingWorkstations }








# Reporting for Critical status objects - weekly to Help Desk

$Script:CriticalServers = $ServerList | Where-Object HealthStatus -eq "Critical"
$Script:CriticalWorkstations = $WorkstationList | Where-Object HealthStatus -eq "Critical"

# ($ServerList).count            #301
# (WorkstationList).count        #5022
# ($UnhealthyServers).count      #0
# ($UnhealthyWorkstations).count #12

function EmailCriticalServers {

$Output = @()

foreach ($Device in $CriticalServers) {

    $OutputDeviceInformation = [PSCustomObject]@{    
        Name = $Device.Name
        LastOnline = $Device.Online
        HealthyStatus = $Device.HealthStatus
        Type = $Device.Type
    }
    $Output += $OutputDeviceInformation

}

$Output = $Output | ConvertTo-HTML -Fragment

$body = @"
<html>  
  <body>
      $Output
  </body>  
</html>  
"@

$params = @{ 
    #Attachment = $Path1, $Path2
    Body = $body 
    BodyAsHtml = $true
    Subject = "Sophos Critical Servers"
    From = 'grc@domain' 
    To = 'me@domain'
    #Cc = 'grc@domain'
    SmtpServer = 'server'
    Port = 25
}
 
Send-MailMessage @params

}

if ($CriticalServers -ne $null) { EmailCriticalServers } 

function EmailCriticalWorkstations {

$Output = @()

foreach ($Device in $CriticalWorkstations) {

    $OutputDeviceInformation = [PSCustomObject]@{    
        Name = $Device.Name
        LastOnline = $Device.Online
        HealthyStatus = $Device.HealthStatus
        Type = $Device.Type
    }
    $Output += $OutputDeviceInformation

}

$Output = $Output | ConvertTo-HTML -Fragment

$body = @"
<html>  
  <body>
      $Output
  </body>  
</html>  
"@

$params = @{ 
    Body = $body 
    BodyAsHtml = $true
    Subject = "Sophos Critical Workstations"
    From = 'grc@domain' 
    To = 'helpdesk@domain'
    Cc = 'me@domain'
    SmtpServer = 'server'
    Port = 25
}
 
Send-MailMessage @params

}

if ($CriticalWorkstations -ne $null) { EmailCriticalWorkstations }











<#
function EmailInactiveServers {

$Output = @()

foreach ($Device in $InactiveServers) {

    $OutputDeviceInformation = [PSCustomObject]@{    
        FullDomainName = $Device
    }
    $Output += $OutputDeviceInformation

}

$Output = $Output | ConvertTo-HTML -Fragment

$body = @"
<html>  
  <body>
      $Output
  </body>  
</html>  
"@

$params = @{ 
    #Attachment = $Path1, $Path2
    Body = $body 
    BodyAsHtml = $true
    Subject = "Sophos AD Inactive Servers"
    From = 'grc@domain' 
    To = 'me@domain'
    #Cc = 'grc@domain'
    SmtpServer = 'server'
    Port = 25
}
 
Send-MailMessage @params

}

if ($InactiveServers -ne $null) { EmailInactiveServers }
#>
<#
function EmailInactiveWorkstations {

$Output = @()

foreach ($Device in $InactiveWorkstations) {

    $OutputDeviceInformation = [PSCustomObject]@{    
        FullDomainName = $Device
    }
    $Output += $OutputDeviceInformation

}

$Output = $Output | ConvertTo-HTML -Fragment

$body = @"
<html>  
  <body>
      $Output
  </body>  
</html>  
"@

$params = @{ 
    #Attachment = $Path1, $Path2
    Body = $body 
    BodyAsHtml = $true
    Subject = "Sophos AD Inactive Workstations"
    From = 'grc@domain' 
    To = 'me@domain'
    #Cc = 'grc@domain'
    SmtpServer = 'server'
    Port = 25
}
 
Send-MailMessage @params

}

if ($InactiveWorkstations -ne $null) { EmailInactiveWorkstations }
#>
# Sam Start

$updateTime      = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

    $InstalledArray=@()
    #Workstations with Sophos Installed
    foreach ($wkstation in $WorkstationList) {
        $InstalledArray += [PSCustomObject]@{
            Name                     = $wkstation.Name;
            Type                     = 'Workstation';
            UpdateTime               = $updateTime;
            SophosInstallationStatus = 'Installed'
        }
    }
    #Servers with Sophos Installed
    foreach ($server in $ServerList) {
        $InstalledArray += [PSCustomObject]@{
            Name                     = $server.Name;
            Type                     = 'Server';
            UpdateTime               = $updateTime;
            SophosInstallationStatus = 'Installed'
        }
    }


    $MissingArray=@()
    #Workstations with Sophos Missing
    foreach ($wkstation in $MissingWorkstations) {
        $MissingArray += [PSCustomObject]@{
            Name                     = $wkstation;
            Type                     = 'Workstation';
            UpdateTime               = $updateTime;
            SophosInstallationStatus = 'Missing'
        }
    }
    #Servers with Sophos Missing
    foreach ($server in $MissingServers) {
        $MissingArray += [PSCustomObject]@{
            Name                     = $server;
            Type                     = 'Server';
            UpdateTime               = $updateTime;
            SophosInstallationStatus = 'Missing'
        }
    }

    $InactiveArray=@()
    #Workstations with Sophos Inactive
    foreach ($wkstation in $InactiveWorkstations) {
        $InactiveArray += [PSCustomObject]@{
            Name                     = $wkstation;
            Type                     = 'Workstation';
            UpdateTime               = $updateTime;
            SophosInstallationStatus = 'Inactive'
        }
    }
    #Servers with Sophos Missing
    foreach ($server in $InactiveServers) {
        $InactiveArray += [PSCustomObject]@{
            Name                     = $server;
            Type                     = 'Server';
            UpdateTime               = $updateTime;
            SophosInstallationStatus = 'Inactive'
        }
    }

    $totalArray = $InstalledArray + $MissingArray + $InactiveArray

    Invoke-DbaQuery      -SqlInstance "server.domain" -Database Sophos -Query "DELETE FROM dbo.InstallationStatus"
    Write-DbaDbTableData -SqlInstance "server.domain" -Database Sophos -Table dbo.InstallationStatus -InputObject $totalArray

