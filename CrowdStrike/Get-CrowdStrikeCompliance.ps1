<#
.SYNOPSIS 
    Identifies missing CrowdStrike Agents and logs ticket to Service Now
	
.DESCRIPTION 
    API call to SSAS platform and PowerShell call from AD to compare lists. Emails results.
	
.NOTES 
	Author:		<redacted>
	Date:		November 8th 2023
	Notes:		Creation
#>

$clientId = "<redacted>"
$clientSecret = "<redacted>"

$headers = @{
    "Content-Type" = "application/x-www-form-urlencoded"
}
$body = @{
    grant_type = "client_credentials"
    client_id = $clientId
    client_secret = $clientSecret
}
$uri = "https://api.crowdstrike.com/oauth2/token"
$tokenResponse = Invoke-RestMethod -Uri $uri -Headers $headers -Method POST -Body $body
$accessToken = $tokenResponse.access_token

$headers = @{
    "Authorization" = "Bearer $accessToken"
}

# Get all host IDs in tenancy
$uri = "https://api.crowdstrike.com/devices/queries/devices-scroll/v1?limit=5000&sort=hostname.asc"
$hosts = Invoke-RestMethod -Uri $uri -Headers $script:headers -Method GET
$allHosts = $hosts.resources

$hostnames = @()
$device = @()

foreach ($entry in $allHosts) {

    $uri = "https://api.crowdstrike.com/devices/entities/devices/v2?ids=$entry"
    $device = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET
    $hostnames += $device.resources.hostname
    }

# Convert $hostnames to upper case
$Script:crowdstrikeAssets = $hostnames | ForEach-Object { $_.ToUpper() }

function processSOE {

$table = @()

$oneWeekAgo = (Get-Date).AddDays(-7)

# Fetch all Active Directory computers within the specified organizational unit (OU)
$excludedOU = "<AD DN>"
$<redacted>ADAssets = Get-ADComputer -Filter { (Enabled -eq $true) -or (WhenChanged -ge $oneWeekAgo) } -SearchBase "<redacted>" | Where-Object { $_.DistinguishedName -notlike "*$excludedOU*" } | Select-Object -ExpandProperty Name

# Convert $<redacted> to upper case
$<redacted>ADAssets = $<redacted>ADAssets | ForEach-Object { $_.ToUpper() }

# Compare the names of assets stored in "$OUADAssets" with the names of assets stored in "$TenableAssets", filtering comparison results to only include entries where the side indicator is "<="
$missingCrowdStrikeAgentSOE = Compare-Object -ReferenceObject $<redacted>ADAssets -DifferenceObject $Script:crowdstrikeAssets |
    Where-Object { $_.SideIndicator -eq '<=' } |
    ForEach-Object { $_.InputObject } |
    Sort

$table = "<table border='1'><tr>"
    foreach ($item in $missingCrowdStrikeAgentSOE) {
        $table += "<tr>$item</tr>"
    }

$table += "</tr></table>"

$body = @"
<html>  
  <body>
      <b><u>Instructions</b></u>
      <br />
      <br />
      The computers listed below within the "<redacted>" Active Directory OU have been identified as not having a counterpart within the CrowdStrike portal. Please check for the presence of the agent on the devices and install if missing. Similarly, there could be a broken or corrupted agent. It may need re-installation.
      <br />
      <br />
      <b><u>Missing CrowdStrike Agents</b></u>
      <br />
      <br />
        $table
  </body>  
</html>  
"@

# Email results
$params = @{ 
    #Attachment = '<filepath>'
    Body = $body 
    BodyAsHtml = $true
    Subject = "Missing CrowdStrike Agents (<redacted> OU)"
    From = '<redacted>' 
    #To = '<redacted>'
    To = '<redacted>'
    Cc = '<redacted>'
    SmtpServer = '<redacted>'
    Port = 25
}
 
Send-MailMessage @params

}

function processServers {

$table = @()

# Now for AD...
$excludeList = "<redacted>", "<redacted>"

$oneWeekAgo2 = (Get-Date).AddDays(-7)

# Fetch all Active Directory computers within the specified organizational unit (OU)
$serversADAssets = Get-ADComputer -Filter { (Enabled -eq $true) -or (WhenChanged -ge $oneWeekAgo2) } -SearchBase "<redacted>" | Where-Object {$excludeList -NotContains $_.Name} | Select-Object -ExpandProperty Name

# Convert $serversADAssets to upper case
$serversADAssets = $serversADAssets | ForEach-Object { $_.ToUpper() }

# Compare the names of assets stored in "$OUADAssets" with the names of assets stored in "$TenableAssets", filtering comparison results to only include entries where the side indicator is "<="
$missingCrowdStrikeAgentServer = Compare-Object -ReferenceObject $serversADAssets -DifferenceObject $Script:crowdstrikeAssets |
    Where-Object { $_.SideIndicator -eq '<=' } |
    ForEach-Object { $_.InputObject } |
    Sort

$table = "<table border='1'><tr>"
    foreach ($item in $missingCrowdStrikeAgentServer) {
        $table += "<tr>$item</tr>"
    }

$table += "</tr></table>"

$body = @"
<html>  
  <body>
      <b><u>Instructions</b></u>
      <br />
      <br />
      The computers listed below within the "Servers" Active Directory OU have been identified as not having a counterpart within the CrowdStrike portal. Please check for the presence of the agent on the devices and install if missing. Similarly, there could be a broken or corrupted agent. It may need re-installation.
      <br />
      <br />
      <b><u>Missing CrowdStrike Agents</b></u>
      <br />
      <br />
        $table
  </body>  
</html>  
"@

# Email results
$params = @{ 
    #Attachment = '<filepath>'
    Body = $body 
    BodyAsHtml = $true
    Subject = "Missing CrowdStrike Agents (<redacted> OU)"
    From = '<redacted>' 
    #To = '<redacted>'
    To = '<redacted>'
    SmtpServer = '<redacted>'
    Port = 25
}
 
Send-MailMessage @params

}

processSOE
processServers

function reportingMetrics {

$ADAssets = $<redacted>ADAssets + $serversADAssets
$missingCrowdStrikeAgents = $missingCrowdStrikeAgentSOE + $missingCrowdStrikeAgentServer

$percentageMetrics = ($missingCrowdStrikeAgents.count / $ADAssets.count)

$inversePercentage = (1 - $percentageMetrics) * 100
$roundedInversePercentage = [math]::Floor($inversePercentage)
$findngMetric = "$roundedInversePercentage%"

$table = "<table border='1'><tr>"
    foreach ($item in $findngMetric) {
        $table += "<tr>$item</tr>"
    }

$table += "</tr></table>"

$body = @"
<html>  
  <body>
      The coverage statistic for CrowdStrike to Active Directory computers is:
      <br />
      <br />
      <b><u>Missing CrowdStrike Agents</b></u>
      <br />
      <br />
        $table
  </body>   
</html>  
"@

# Email results
$params = @{ 
    #Attachment = '<filepath>'
    Body = $body 
    BodyAsHtml = $true
    Subject = "Metric Report: CrowdStrike Agent Coverage"
    From = '<redacted>' 
    #To = '<redacted>'
    #To = '<redacted>'
    To = '<redacted>'
    SmtpServer = '<redacted>'
    Port = 25
}
 
Send-MailMessage @params

}

reportingMetrics
