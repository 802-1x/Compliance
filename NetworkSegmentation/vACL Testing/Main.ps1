
function StandardReport {

    $ComputerTarget = Read-Host -Prompt 'Enter target computer'
    $ComputerSession = New-PSSession -ComputerName $ComputerTarget

    Copy-Item -Path \\path\path$\Powershell\vACLTest.ps1 -Destination "\\$ComputerTarget\C$\temp\vACLTest.ps1"
    Copy-Item -Path \\path\path$\Powershell\vACLTesting.csv -Destination "\\$ComputerTarget\C$\temp\vACLTesting.csv"

    Invoke-Command -Session $ComputerSession -ScriptBlock {

        $CurrentEP = Get-ExecutionPolicy
        Set-ExecutionPolicy Unrestricted
    
        $ComputerTarget = hostname
        cd "\\$ComputerTarget\C$\temp\"
        .\vACLTest.ps1

        Set-ExecutionPolicy $CurrentEP

    }

    Remove-Item "\\$ComputerTarget\C$\temp\vACLTest.ps1"
    Remove-Item "\\$ComputerTarget\C$\temp\vACLTesting.csv"

}


function CustomReport {

    $FriendlyName = "server"
    $IP = "serverIP"
    $Port = "3389"

    Write-Host "`n Ping Connection Testing `n" -ForegroundColor Cyan

    if (Test-Connection $IP -Count 1 -ErrorAction SilentlyContinue) {
        write-host $FriendlyName "(" $IP ")" "is accessible!" -ForegroundColor Green }
    else {
        write-host $FriendlyName "(" $IP ")" "is not accessible!" -ForegroundColor Red }

    Write-Host "`n Port Connection Testing `n" -ForegroundColor Cyan

    if (Test-NetConnection $IP -Port $Port -WarningAction SilentlyContinue) {
        write-host $FriendlyName "(" $IP ":" $Port ")" "is accessible!" -ForegroundColor Green }
    else {
        write-host $FriendlyName "(" $IP ":" $Port ")" "is not accessible!" -ForegroundColor Red }

}
