# Query for closed recurring issues
$Headers = @{ Authorization = 'token {0}' -f $ENV:GITHUB_TOKEN; };
$result = Invoke-RestMethod -Headers $Headers -Uri "https://api.github.com/repos/Tratcher/SharedTasks/issues?state=closed&labels=Recurring"
$result
