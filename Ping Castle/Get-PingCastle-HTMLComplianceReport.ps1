


$url = "https://github.com/vletoux/pingcastle/releases/latest"

# Send a GET request to the URL
$response = Invoke-WebRequest -Uri $url

# Extract the URL of the latest release
$latestReleaseUrl = $response.BaseResponse.ResponseUri.AbsoluteUri

# Display the captured URL
Write-Output "Latest Release URL: $latestReleaseUrl"

# Truncate the text after the last /
$latestReleaseName = (Split-Path $latestReleaseUrl -Leaf)

# Display the captured release name
Write-Output "Latest Release Name: $latestReleaseName"




#Generate report files.
$fileExecutable = "C:\Users\<redacted>\Downloads\PingCastle_2.10.1.1\PingCastle.exe"
Start-Process -NoNewWindow -FilePath "$fileExecutable" -ArgumentList "--healthcheck --server <redacted>"

# Load XML from file for analysis
$xml = [xml](Get-Content -Path "C:\Users\<redacted>\Downloads\PingCastle_2.10.1.1\<redacted>.xml")

$xml.HealthCheckData.GlobalScore
$xml.EngineVersion
$xml.

$latestReleaseName
