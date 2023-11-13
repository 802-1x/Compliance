<#
.SYNOPSIS 
    This PowerShell script compares the latest version of a specified program with the currently installed version. If a mismatch is detected, the script sends an email notification to the administrator, prompting them to take necessary actions.
	
.DESCRIPTION 
    This script automates the version comparison process for a designated program. It fetches the latest version information and compares it with the installed version on the system. In case of a version mismatch, the script generates an email notification alerting the administrator to review and update the application. This provides a proactive approach to maintaining up-to-date software across the system, enhancing security and performance.
	
.NOTES 
	Author:		<redacted>
	Date:		November 13th 2023
	Notes:		Creation
#>

#Set the TLS version level, which is required if lower versions are disabled within a server environment
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Query Duo for the latest executable installable and get the exe name
$url = "https://dl.duosecurity.com/duoauthproxy-latest.exe"
$response = Invoke-WebRequest -Method Head -Uri $url -UseBasicParsing
$contentDisposition = $response.Headers["Content-Disposition"]
if ($contentDisposition -ne $null) {
    $latestExecutable = ($contentDisposition -split ";")[-1].Split("=")[-1].Trim('"')
    Write-Output "The latest client version is: $latestExecutable"
}

# Define registry path for installed applications
$registryPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"

# Get installed applications from the registry
$installedApplications = Get-ItemProperty -Path $registryPath | Where-Object { $_.DisplayName -ne $null }

# Find the target application within the installed applications
$targetApplication = $installedApplications | Where-Object { $_.DisplayName -like "Duo Security Authentication Proxy*" }
$currentExecutable = "duoauthproxy-" + $targetApplication.DisplayVersion + ".exe"

# Compare the variables
if ($latestExecutable -eq $currentExecutable) {

    Write-Host "The variables are equal."
    exit

}

Write-Output "The latest client version is: $currentExecutable"
Write-Host "The variables are not equal."

$hostname = hostname

$body = @"
<html>  
  <body>
      <b><u>Upgrade Required</b></u>
      <br />
      <br />
      $currentExecutable has not been updated with $latestExecutable. Please review and plan an upgrade accordingly.
      <br />
      <br />
      The generating server is $hostname.
  </body>   
</html>  
"@

$params = @{ 
    Body = $body 
    BodyAsHtml = $true
    Subject = "Duo Authentication Proxy Upgrade Required"
    From = '<redacted>' 
    To = '<redacted>'
    SmtpServer = '<redacted>'
    Port = 25
}

Write-Host "Sending email to an administrator"

Send-MailMessage @params
