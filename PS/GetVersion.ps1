try{

    $versionFromServer = (Invoke-webrequest -URI "https://www.3shape.com/currentbuildtag.txt")
    # $versionFromServer = (Invoke-webrequest -URI "https://3shape-sitecore-test1-cd.azurewebsites.net/currentbuildtag.txt").Content
    Write-Host "Status code" $versionFromServer.StatusCode
    if($versionFromServer.StatusCode -eq 200){
        Write-Host "Currently deployed build: "$versionFromServer.Content
    }
    
}
catch{
    Write-Host "Could not access file" $_.Exception.Response.StatusCode.value__
    exit 0
    Write-Host "Should not be here"
}
Write-Host "After try catch"$versionFromServer