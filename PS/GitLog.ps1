# $bytes = [System.Text.Encoding]::UTF8.GetBytes("$username`:$password")
# $encodedCredentials = [System.Convert]::ToBase64String($bytes)
# function Get-JiraIssue {    
#   # We need authentication token
#   param([string] $issueId)
#   return Invoke-RestMethod -Uri "https://jira.3shape.com/rest/api/latest/issue/$issueId" -Headers @{"Authorization" = "Basic $encodedCredentials" } -ContentType application/json 
# }
$jira_url = "https://jira.3shape.com"
$commits = git log --pretty=oneline "baadcb6af9b7987c9536ae37921b78c271734148...c2d1ce2ae20964b6a0cfc04238ed9dbf35e911a8" --no-decorate --no-merges --pretty=format:"%ai`t%H`t%an`t%ae`t%s" | ConvertFrom-Csv -Delimiter "`t" -Header ("Commit Date", "Commit Id", "Commit Author", "Commit Email", "Commit Message")

$commits | ForEach-Object {
    if ($_."Commit Message" -match "(^[a-zA-Z]{2,8}\-[0-9]+)") {
        Write-Host "Match on $($_."Commit Message")"
        Write-Host "Match "$Matches[0]
        $jiraTicket = $Matches[0]
        #$dashPos = $Matches[0].Split("-")[0]
        $projectPart = $Matches[0].Split("-")[0] #$Matches.Substring(0, $dashPos)
        Write-Host "Project " $projectPart
        # $jiraIssue = Get-JiraIssue($Matches[0])
        # Write-Host "Jira issue key " $jiraIssue.key
        $_ | Add-Member -NotePropertyName "Jira Key" -NotePropertyValue $jiraTicket
        $_ | Add-Member -NotePropertyName "Jira URL" -NotePropertyValue "$jira_url/browse/$jiraTicket"
        #$_ | Add-Member -NotePropertyName "Commit message" -NotePropertyValue $jiraIssue.fields.summary
        $_ | Add-Member -NotePropertyName "Jira Project Key" -NotePropertyValue $projectPart #$jiraIssue.fields.project.key
        $_ | Add-Member -NotePropertyName "Project Name" -NotePropertyValue $projectPart #$jiraIssue.fields.project.name
    }
    else {
        Write-Host "No match on $($_."Commit Message")"
        $_ | Add-Member -NotePropertyName "Jira Key" -NotePropertyValue $_."Commit Id"
        $_ | Add-Member -NotePropertyName "Jira URL" -NotePropertyValue ""
        #$_ | Add-Member -NotePropertyName "Jira Summary" -NotePropertyValue $_."Commit Message"
        $_ | Add-Member -NotePropertyName "Jira Project Key" -NotePropertyValue "NoProjectKey"
        $_ | Add-Member -NotePropertyName "Project Name" -NotePropertyValue "Not related to Jira"
    }  
}

Write-Host "Checked for commit messages"

$projects = $commits | Select-Object "Project Name", "Jira Project Key" | sort-object -Property "Project Name" -Unique
$projects = @($projects)
$projects | ForEach-Object {
    $projectName = $_."Project Name"
    $projectKey = $_."Jira Project Key"
    $_ | Add-Member -NotePropertyName "Number of commits" -NotePropertyValue (@($commits | Where-Object { $_."Project Name" -eq $projectName } )).Count
    $_ | Add-Member -NotePropertyName "Number of Jira Issues Affected" -NotePropertyValue @($commits | Where-Object { $_."Jira Project Key" -eq $projectKey } | Group-Object -Property "Jira Key" | Select-Object Name, Count  ).Count
}

$projectTable = $projects | Select-Object -Property "Project Name", @{N = "# of affacted Jira tickets"; E = { $_."Number of Jira Issues Affected" } }, @{N = "# of git commits"; E = { $_."Number of commits" } } 

$releaseNotes += "<p>Release notes from comparing release <code>$tag1</code> with <code>$tag2</code></p>";
Write-Host "Release notes from comparing release $tag1 with $tag2"
$releaseNotes += "<h1>Projects included in this release</h1>";
Write-Host "Projects included in this release"
$releaseNotes += $projectTable | ConvertTo-Html -Fragment
$projectTable | Format-Table

$projects | ForEach-Object {
    $releaseNotes += "<h2>Project: $($_."Project Name")</h2>"
    Write-Host "Project: $($_."Project Name")"
    $projectKey = $_."Jira Project Key"
    $tickets = $commits | Where-Object { $_."Jira Project Key" -eq $projectKey } | Select-Object "Jira Key", "Jira URL", "Commit message" | sort-object -Property "Jira Key" #-Unique 

    $ticketsTable = $tickets | Select-Object -Property @{N = "Jira #"; E = { "<a href=""$($_."Jira URL")"">$($_."Jira Key")</a>" } }, @{N = "Commit message" ; E = { [System.Web.HttpUtility]::HtmlEncode($_."Commit message")} } 
    $ticketsTable | Format-Table
    $releaseNotes += $ticketsTable | ConvertTo-Html -Fragment;
}

$decoded = [System.Web.HttpUtility]::HtmlDecode($releaseNotes);