<#
.SYNOPSIS 
    Utilising Duo API to query data and process it for useful tenancy statistics.
	
.DESCRIPTION 
    A toolbox of modules for querying Duo API and retrieving telemetry and statistical information. This script is dependant upon mbegan's work (https://github.com/mbegan/Duo-PSModule).
	
.NOTES 
	Author:		<redacted>
	Date:		November 10th 2023
	Notes:		Creation
#>

# Secrets file: # C:\Users\%username%\Documents\WindowsPowerShell\Modules\Duo
# Use duoEncskey to generate encrypted string

Import-Module Duo

#We need the Epoch standard formating to pass through the API
$tempDate = (Get-Date).AddDays(-3)
$minDateUTC = Get-Date $tempDate -UFormat "%Y-%m-%d %H:%M:%S"
$unixTimestamp = [Math]::Floor(([DateTime]'1/1/1970').ToUniversalTime().Ticks - ([DateTime]$minDateUTC).ToUniversalTime().Ticks) / [TimeSpan]::TicksPerSecond
$unixTimestamp = [Math]::Abs($unixTimestamp)
$dateTime = [DateTime]::FromFileTimeUtc(([Int64]($unixTimestamp + 11644473600) * 10000000))

$Script:duoAuthLogs = duoGetLog -mintime $unixTimestamp -log authentication

function Top25AuthFailures {

# Retrieve top 25 most frequent users who fail authentication, group results, and show in descending order
$Script:top25FailedAuths = $duoAuthLogs | Where-Object { $_.result -eq "FAILURE" } | Group-Object -Property username | Sort-Object -Property Count -Descending | Select-Object -First 25 -Property Name, Count

}

Top25AuthFailures

function nonAUAuthentication {

# Country not value

$country = "AU"

$Script:authsNotAU = @()

foreach ($instance in $duoAuthLogs) {
    if ($instance.Location.Country -ne $country) {
        $Script:authsNotAU += $instance
    }
}
}
