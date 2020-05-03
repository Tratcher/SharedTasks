$todaysDate = [System.DateTime]::Now.Date
"Today's Date: " + $todaysDate

# Query for closed recurring issues
$Headers = @{ Authorization = 'token {0}' -f $ENV:GITHUB_TOKEN; };
$result = Invoke-RestMethod -Headers $Headers -Uri "https://api.github.com/repos/Tratcher/SharedTasks/issues?state=closed&labels=Recurring"

# Parse each issue
ForEach ($item in $result)
{
 "Title: " + $item.title
 $closedDate = [System.DateTimeOffset]::Parse($item.closed_at).Date
 "Closed at: " + $closedDate
 
 $every = "";
 $unit = "";
 $sense = "";
 $on = "";
 $reader = New-Object -TypeName System.IO.StringReader -ArgumentList $item.body
 while ($True)
 {
  $line = $reader.ReadLine();

  if ($line -eq $null)
  {
      break;
  }

  if ($line.Equals("#### Recurrence Schedule"))
  {
    # Every
    $line = $reader.ReadLine();
    if ($line -eq $null)
    {
        break;
    }

    $everyLineWords = $line.Split(' ');
    if ($everyLineWords.Count -gt 1 -and [System.String]::Equals($everyLineWords[0], "Every:", [System.StringComparison]::OrdinalIgnoreCase))
    {
        $every = $everyLineWords[1];
    }
    
    # Unit
    $line = $reader.ReadLine();
    if ($line -eq $null)
    {
        break;
    }

    $unitLineWords = $line.Split(' ');
    if ($unitLineWords.Count -gt 1 -and [System.String]::Equals($unitLineWords[0], "Unit:", [System.StringComparison]::OrdinalIgnoreCase))
    {
        $unit = $unitLineWords[1];
    }
    
    # Since
    $line = $reader.ReadLine();
    if ($line -eq $null)
    {
        break;
    }

    $sinceLineWords = $line.Split(' ');
    if ($sinceLineWords.Count -gt 1 -and [System.String]::Equals($sinceLineWords[0], "Since:", [System.StringComparison]::OrdinalIgnoreCase))
    {
        $since = $sinceLineWords[1];
    }

    # On
    $line = $reader.ReadLine();
    if ($line -eq $null)
    {
        break;
    }

    $onLineWords = $line.Split(' ');
    if ($onLineWords.Count -gt 1 -and [System.String]::Equals($onLineWords[0], "On:", [System.StringComparison]::OrdinalIgnoreCase))
    {
        $on = $onLineWords[1];
    }
    
    break;
  }
 }
 $every
 $unit
 $since
 $on

 $reopen = false
 if ([System.String]::Equals($unit, "Days", [System.StringComparison]::OrdinalIgnoreCase))
 {
    $every
    $unit
    $since
    $reopen = $True
 }
 elseif ([System.String]::Equals($unit, "Weeks", [System.StringComparison]::OrdinalIgnoreCase))
 {
    $every
    $unit
    $since
    $on
    if ($todaysDate.DayOfWeek -eq $on)
    {
      $reopen = $True
    }
 }
 elseif ([System.String]::Equals($unit, "Months", [System.StringComparison]::OrdinalIgnoreCase))
 {
    $every
    $unit
    $since
    $on
    if ($todaysDate.Day -eq $on)
    {
      $reopen = $True
    }
 }
 else
 {
   "Unrecognized unit: " + $unit
 }
 $reopen
 if ($reopen)
 {
  "Reopen"
  $json = "{ `"state`": `"open`" }"
  $result = Invoke-RestMethod -Method PATCH -Headers $Headers -Uri $item.url -Body $json
  $result
 }
}
return 0;
