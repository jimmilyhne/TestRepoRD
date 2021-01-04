$versionFromServer = (Invoke-webrequest -URI "https://www.3shape.com/version.txt").Content
Write-Host "Currently deployed build: " $versionFromServer.Trim()