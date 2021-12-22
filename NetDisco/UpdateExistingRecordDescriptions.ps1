# Update exiting record descriptions
Import-Module dbatools
$current = Invoke-DbaQuery -SqlInstance server -Database Sophos -Query "SELECT * FROM [dbo].[netdiscoNewDevices]"
foreach($c in $current){
    $assetName = $c.dns.Split("{.}")[0]
    $desc = Get-ADComputer $assetName -Properties Description
    $desc = $desc.Description
    $id = $c.id
    $asset = $c.DNS
    if($null -ne $desc){Invoke-DbaQuery -SqlInstance server -Database db -Query "UPDATE [dbo].[netdiscoNewDevices] SET Description = '$desc' WHERE id = '$id' AND DNS = '$asset'"}
    Write-Host $desc
}
