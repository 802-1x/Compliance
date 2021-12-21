#Send daily email from application export
$CurrentDate = Get-Date -Format 'dd-MM-yyyy'
$Recipient = 'email'
$Subject   = "Application Name Report $CurrentDate"
$Attachment = "\\Server\e$\Application Name\Application Name Report.csv"
$AttachmentDate = Get-ChildItem $Attachment ; $AttachmentDate = $AttachmentDate.LastWriteTime ; $AttachmentDate = Get-Date($AttachmentDate) -Format 'dd-MM-yyyy hh:mm:ss'
$Message   = 
@"
<html>
<body>
<br>
Please find attached the Application Name Report for: $AttachmentDate
</body>
<footer><p><sub>Scheduled Task: Application - Send Entry Report</sub></footer>
</html>
"@

Send-MailMessage -To $Recipient -Subject $Subject -From noreplies@domain -BodyAsHTML $Message -Attachment $Attachment -smtpserver SMTPFQDN
