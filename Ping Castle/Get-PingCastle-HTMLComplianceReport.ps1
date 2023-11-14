#WIP

$fileExecutable = "C:\Users\<redacted>\Downloads\PingCastle_2.10.1.1\PingCastle.exe"

Start-Process -NoNewWindow -FilePath "$fileExecutable" -ArgumentList "--healthcheck --server <redacted>"

