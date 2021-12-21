# Process the Workstation and Server Reports from Sophos Central received from the automated email reports. The attachments are stripped out using K2 and exported to CSV.
Import-Module dbatools

$wkstationFile          = Get-ChildItem "\\server\download\K2\Sophos\Computers*.csv" | Sort-Object LastWriteTime | Select-Object -Last 1
$serverFile             = Get-ChildItem "\\server\download\K2\Sophos\Servers*.csv"   | Sort-Object LastWriteTime | Select-Object -Last 1
$script:wkstationReport = Import-Csv $wkstationFile
$script:serverReport    = Import-Csv $serverFile
$script:updateTime      = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$log                    = "\\server\download\K2\Sophos\log\log.txt"

function processReport {
    # Process the workstations and add a workstation type flag
    $script:wkstationArray=@()
    foreach ($wkstation in $wkstationReport) {
        $script:wkstationArray += [PSCustomObject]@{
            Name                    = $wkstation.Name;
            Online                  = $wkstation.Online;
            LastUser                = $wkstation.'Real-time Scan';
            LastLoginTime           = $wkstation.'Last Login Time';
            RealTimeScan            = $wkstation.'Real-time Scan';
            LastUpdate              = $wkstation.'Last Update';
            LastScheduledScan       = $wkstation.'Last Scheduled Scan';
            LastScheduledScanTime   = $wkstation.'Last Scheduled Scan Time';
            EncryptionStatus        = $wkstation.'Encryption Status';
            HealthStatus            = $wkstation.'Health Status';
            Group                   = $wkstation.Group;
            Type                    = 'Workstation';
            UpdateTime              = $updateTime
        }
    }

    # Process the servers and add a server type flag
    $script:serverArray=@()
    foreach ($server in $serverReport) {
        $script:serverArray += [PSCustomObject]@{
            Name                    = $server.Name;
            Online                  = $server.Online;
            LastUser                = $server.'Real-time Scan';
            LastLoginTime           = $server.'Last Login Time';
            RealTimeScan            = $server.'Real-time Scan';
            LastUpdate              = $server.'Last Update';
            LastScheduledScan       = $server.'Last Scheduled Scan';
            LastScheduledScanTime   = $server.'Last Scheduled Scan Time';
            EncryptionStatus        = $server.'Encryption Status';
            HealthStatus            = $server.'Health Status';
            Group                   = $server.Group;
            Type                    = 'Server';
            UpdateTime              = $updateTime
        }
    }
} 
# Check for available update file, condense reports and update SQL, add log entry
if($null -ne $serverReport -and $null -ne $wkstationReport){
    processReport
    $totalReport = $wkstationArray + $serverArray
    Invoke-DbaQuery      -SqlInstance "ServerFQDN" -Database Sophos -Query "DELETE FROM dbo.CentralReport"
    Write-DbaDbTableData -SqlInstance "ServerFQDN" -Database Sophos -Table dbo.CentralReport -InputObject $totalReport
    $wkstationReportFilename = Get-ChildItem -Path "\\server\download\K2\Sophos\Computers*.csv"
    $serverReportFilename    = Get-ChildItem -Path "\\server\download\K2\Sophos\Servers*.csv"
    "$updateTime Wrote $wkstationReportFilename.Name" | Out-File $log -Append
    "$updateTime Wrote $serverReportFilename.Name"    | Out-File $log -Append
    Remove-Item -Path "\\server\download\K2\Sophos\*.*" -Force
}
