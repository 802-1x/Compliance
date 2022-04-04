$PSDefaultParameterValues['Test-NetConnection:InformationLevel'] = 'Quiet'
$Global:ProgressPreference = 'SilentlyContinue'

#$SourceData = Import-CSV -Path \\path\path$\Powershell\vACLTesting.csv
$SourceData = Import-CSV -Path .\vACLTesting.csv
$PingUp = $SourceData | Where-Object Port -eq ''
$PortOpen = $SourceData | Where-Object Port -ne ''

Write-Host "`n Ping Connection Testing `n" -ForegroundColor Cyan

foreach ($IP in $PingUp) {
    
    if (Test-Connection $IP.IP -Count 1 -ErrorAction SilentlyContinue) {
        write-host $IP.FriendlyName "(" $IP.IP ")" "is accessible!" -ForegroundColor Green }
    else {
        write-host $IP.FriendlyName "(" $IP.IP ")" "is not accessible!" -ForegroundColor Red }

}

Write-Host "`n Port Connection Testing `n" -ForegroundColor Cyan

foreach ($IP in $PortOpen) {
    
    if (Test-NetConnection $IP.IP -Port $IP.Port -WarningAction SilentlyContinue) {
        write-host $IP.FriendlyName "(" $IP.IP ":" $IP.Port ")" "is accessible!" -ForegroundColor Green }
    else {
        write-host $IP.FriendlyName "(" $IP.IP ":" $IP.Port ")" "is not accessible!" -ForegroundColor Red }

}
