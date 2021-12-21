# Process the Workstation and Server Reports from Sophos Central received from the automated email reports. The attachments are stripped out using K2 and exported to CSV.
Import-Module dbatools

$wkstationReport = Import-Csv -Path "\\server\download\K2\Sophos\Computers*.csv"
$serverReport    = Import-Csv -Path "\\server\download\K2\Sophos\Servers*.csv"
$updateTime      = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
function processFiles {
    # Process the workstations and add a workstation type flag
    $wkstationArray=@()
    foreach ($wkstation in $wkstationReport) {
        $wkstationArray += [PSCustomObject]@{
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
            Type                    = 'Wokstation';
            UpdateTime              = $updateTime
        }
    }

    # Process the servers and add a server type flag
    $serverArray=@()
    foreach ($server in $serverReport) {
        $serverArray += [PSCustomObject]@{
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

 
if($null -ne $wkstationReport -and $null -ne $serverReport){
    processFiles
    $totalReport = $wkstationArray + $serverArray
    $clearTable  = Invoke-DbaQuery      -SqlInstance "serverfqdn" -Database Sophos -Query "DELETE FROM dbo.CentralReport"
    $updateTable = Write-DbaDbTableData -SqlInstance "serverfqdn" -Database Sophos -Table dbo.CentralReport -InputObject $totalReport
    Remove-Item -Path "\\server\download\K2\Sophos\*.*" -Force
}
