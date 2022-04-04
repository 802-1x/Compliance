
$CurrentDate = Get-Date
$Days = -61 #AD password renewal date and SCCM databse retention period
$DaysToDelete = -91

$LogDate = Get-Date -format yyyyMMddhhmm
$ScriptLogPath = $PsScriptRoot+"\Script Log\"
$ResultsLogPath = $PsScriptRoot+"\Results\"

Start-Transcript $ScriptLogPath\$LogDate"_AgedComputersScript.log"

Import-Module ActiveDirectory

Write-Host "Current Date = $CurrentDate"
Write-Host "Days Aged = $Days"
Write-Host "Days to Delete = $DaysToDelete"

#Disables and moves aged Computer objects from the workstation root OU
$LastLogonDateCheck = $CurrentDate.AddDays($Days)
$AgedComputers = Get-ADComputer -SearchBase "DNPATH"  -Filter {LastLogon -lt $LastLogonDateCheck -and Enabled -eq $true} -Properties Name,Description,lastlogon,distinguishedName,memberof | `
                 tee-object -file $ResultsLogPath$LogDate"_AgedComputers.log" | `
                 Move-ADObject -targetpath "COMPUTERS FOR DELETION DN PATH" -PassThru | `
                 Set-ADComputer -Enabled $false
#This returns the "lastlogon" as [fileTime] need to use [datetime]::FromFileTime("*ValueAsInt*") to convert it back

#Deletes Old Computer objects from the Computers for Deletions OU
$WhenDisabledLogonDateCheck = $CurrentDate.AddDays($DaysToDelete)
$DeleteComputers = Get-ADComputer -SearchBase "COMPUTERS FOR DELETION DN PATH" -Filter {LastLogon -lt $WhenDisabledLogonDateCheck -and Enabled -eq $false} -Properties Name,Description,lastlogon,distinguishedName,memberof,useraccountcontrol | `
                 Tee-object -file $ResultsLogPath$LogDate"_DeletedComputers.log" | `
                 Remove-ADComputer -Confirm:$false

Stop-Transcript
