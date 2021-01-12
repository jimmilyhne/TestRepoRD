$commits = git log --pretty=oneline "baadcb6af9b7987c9536ae37921b78c271734148...71e6acae50d3332c07d00cf1f7e2cc67632dce4e" --no-decorate --no-merges --pretty=format:"%ai`t%H`t%an`t%ae`t%s" | ConvertFrom-Csv -Delimiter "`t" -Header ("Commit Date", "Commit Id", "Commit Author", "Commit Email", "Commit Message")

$commits | ForEach-Object {
    if ($_."Commit Message" -match "(^[a-zA-Z]{2,8}\-[0-9]+)") {
      Write-Host "Match on $($_."Commit Message")"
    }
    else {
        Write-Host "No match on $($_."Commit Message")"
    }  
}