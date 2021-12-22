Import-Module ActiveDirectory

$ProblemComputers = Get-ADComputer -Filter {(Enabled -eq $True)} -SearchBase "OU=Computers For Deletion,OU"

foreach ($PC in $ProblemComputers) { Disable-ADAccount -Identity $PC }
