#Send a reminder to x if x backups haven't been completed in the last 2 weeks
$backupDirs  = Get-ChildItem '\\server\share$\lab'
$today       = Get-Date
$backupTable = $null

# Find the last modified date for each x machine backup folder
foreach ($dir in $backupDirs) {
    if($dir.Name -ne 'archive'){
        $testLastBackup = New-TimeSpan -Start $today -End $dir.LastWriteTime
        if($testLastBackup.Days -lt -30){
            $Name = $dir.Name;
            $Date = $dir.LastWriteTime | Get-Date -Format 'dd/MM/yyyy hh:mm:ss'
            $compDesc = Get-ADComputer $Name -Property Description | Select-Object -ExpandProperty Description
$backupRow = @"
<tr><b><td class="offline"><h2>$Name</td><td class="offline">  $compDesc</td></b></tr>
<tr><b><td>Last backup</td></b><td> $Date</h2></td></tr>
<tr><b><td class="offline">&nbsp;&nbsp;&nbsp;</td><td class="offline">&nbsp;&nbsp;</td></b></tr>
<tr><b><td>&nbsp;&nbsp;</td></b><td>&nbsp;&nbsp;</td></tr>
"@
            $backupTable += $backupRow
		}
    }
}

# Create HTML report

$HTMLHeader = @"
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">
<html><head><title>x Backup Reminder</title>
<style type="text/css">
<!--
body {
font-family: Verdana, Geneva, Arial, Helvetica, sans-serif;
}

    #report { width: 835px; }

    table{
	border-collapse: collapse;
	border: none;
	font: 10pt Verdana, Geneva, Arial, Helvetica, sans-serif;
	color: black;
	margin-bottom: 10px;
}

    table td{
	font-size: 12px;
	padding-left: 0px;
	padding-right: 20px;
	text-align: left;
}

    table th {
	font-size: 12px;
	font-weight: bold;
	padding-left: 0px;
	padding-right: 20px;
	text-align: left;
}

h2{ clear: both; font-size: 130%; }

h3{
	clear: both;
	font-size: 115%;
	margin-left: 20px;
	margin-top: 30px;
}

p{ margin-left: 20px; font-size: 12px; }

table.list{ float: left; }

    table.list td:nth-child(1){
	font-weight: bold;
	border-right: 1px grey solid;
	text-align: right;
}

table.list td:nth-child(2){ padding-left: 7px; }
table tr:nth-child(even) td:nth-child(even){ background: #CCCCCC; }
table tr:nth-child(odd) td:nth-child(odd){ background: #F2F2F2; }
table tr:nth-child(even) td:nth-child(odd){ background: #DDDDDD; }
table tr:nth-child(odd) td:nth-child(even){ background: #E5E5E5; }
table.list tr td.offline { background-color: #fc7d7d; !important; }
table.list tr td.online { background-color: #7dfc86; !important; }
table.list tr td.old { background-color: #e95bff; !important; }
div.column { width: 320px; float: left; }
div.first{ padding-right: 20px; border-right: 1px  grey solid; }
div.second{ margin-left: 30px; }
table{ margin-left: 20px; }
-->
</style>
</head>
<body>
<p><h2>x backup reminder > 30 days</h2></p>
<p>
This is an automated reminder to run the backup script located on the desktop of each Application PC when possible.
<br><br>
Please be aware that the backup takes ~1 hour and the machine cannot be used during the process.
<br><br>
<p>
<table>
"@

#Close of entire HTML report
$HTMLEnd = @"
</table>
</body>
</html>
"@

$HTMLMessage = $HTMLHeader + $backupTable +  $HTMLEnd
if($null -ne $backupTable){Send-MailMessage -To user@domain,user2@domain -bcc me@domain -Subject 'Application Backups Reminder' -From noreplies@domain -BodyAsHtml $HTMLmessage -smtpserver SMTP_FQDN}
#if($null -ne $backupTable){Send-MailMessage -To me@domain -Subject 'Application Backups Reminder' -From noreplies@domain -BodyAsHtml $HTMLmessage -smtpserver SMTP_FQDN}
