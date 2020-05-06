$timeZone = [System.TimeZoneInfo]::FindSystemTimeZoneById("Pacific Standard Time")
"Local Time Zone: " + $timeZone
$todaysDateUtc = [System.DateTimeOffset]::UtcNow
"Today's Date UTC: " + $todaysDateUtc
$todaysDate = [System.TimeZoneInfo]::ConvertTime($todaysDateUtc, $timeZone).Date
"Today's Date: " + $todaysDate

# Query for closed recurring issues
$Headers = @{ Authorization = 'token {0}' -f $ENV:GITHUB_TOKEN; };
$result = Invoke-RestMethod -Headers $Headers -Uri "https://api.github.com/repos/Tratcher/SharedTasks/issues?state=closed&labels=Recurring"

# Parse each issue
ForEach ($item in $result)
{
  "Title: " + $item.title
  $createdDateUtc = [System.DateTimeOffset]::Parse($item.created_at)
  "Created Date UTC: " + $createdDateUtc
  $createdDate = [System.TimeZoneInfo]::ConvertTime($createdDateUtc, $timeZone).Date
  "Created Date: " + $createdDate
  $closedDateUtc = [System.DateTimeOffset]::Parse($item.closed_at)
  "Closed Date Utc: " + $closedDateUtc
  $closedDate = [System.TimeZoneInfo]::ConvertTime($closedDateUtc, $timeZone).Date
  "Closed Date: " + $closedDate

  $every = "";
  $unit = "";
  $since = "";
  $on = "";
  $body = $item.body
  $reader = New-Object -TypeName System.IO.StringReader -ArgumentList $body
  while ($True)
  {
    $line = $reader.ReadLine();
    if ($line -eq $null)
    {
        break;
    }

    if (!$line.Equals("#### Recurrence Schedule"))
    {
      continue;
    }

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

  "Unit: " + $unit
  $reopen = $false
  if ([System.String]::Equals($unit, "Days", [System.StringComparison]::OrdinalIgnoreCase))
  {
     "Since: " + $since
     if ([System.String]::Equals($since, "Completed", [System.StringComparison]::OrdinalIgnoreCase))
     {
       $days = ($todaysDate - $closedDate).TotalDays
       "Total Days: " + $days
       "Every: " + $every
       if ($every -le $days)
       {
         $reopen = $True
       }
     }
     elseif ([System.String]::Equals($since, "Scheduled", [System.StringComparison]::OrdinalIgnoreCase))
     {
       $days = ($todaysDate - $createdDate).TotalDays
       "Total Days: " + $days
       "Every: " + $every
       if (($days % $every) -eq 0)
       {
         $reopen = $True
       }
     }
     else
     {
       "Unrecognized Since: " + $since
     }
  }
  elseif ([System.String]::Equals($unit, "Weeks", [System.StringComparison]::OrdinalIgnoreCase))
  {
     "Since: " + $since
     if ([System.String]::Equals($since, "Completed", [System.StringComparison]::OrdinalIgnoreCase))
     {
       [int] $weeks = [System.Math]::Floor(($todaysDate - $closedDate).TotalDays / 7)
       "Total Weeks: " + $weeks
       "Every: " + $every
       if ($every -le $weeks)
       {
         "On: " + $on
         if ([System.String]::IsNullOrEmpty($on) -or $todaysDate.DayOfWeek -eq $on)
         {
           $reopen = $True
         }
       }
     }
     elseif ([System.String]::Equals($since, "Scheduled", [System.StringComparison]::OrdinalIgnoreCase))
     {
       [int] $weeks = [System.Math]::Floor(($todaysDate - $createdDate).TotalDays / 7)
       "Total Weeks: " + $weeks
       "Every: " + $every
       if (($weeks % $every) -eq 0)
       {
         "On: " + $on
         if ([System.String]::IsNullOrEmpty($on) -or $todaysDate.DayOfWeek -eq $on)
         {
           $reopen = $True
         }
       }
     }
     else
     {
       "Unrecognized Since: " + $since
     }
  }
  elseif ([System.String]::Equals($unit, "Months", [System.StringComparison]::OrdinalIgnoreCase))
  {    
     "Since: " + $since
     if ([System.String]::Equals($since, "Completed", [System.StringComparison]::OrdinalIgnoreCase))
     {
       "Every:" + $every
       if ($closedDate.AddMonths($every) -le $todaysDate)
       {
         "On: " + $on
         if ([System.String]::IsNullOrEmpty($on) -or $todaysDate.Day -eq $on)
         {
           $reopen = $True
         }
       }
     }
     elseif ([System.String]::Equals($since, "Scheduled", [System.StringComparison]::OrdinalIgnoreCase))
     {
       $months = (($todaysDate.Year - $createdDate.Year) * 12) + ($todaysDate.Month - $createdDate.Month)
       "Total Months: " + $months
       "Every: " + $every
       if (($months % $every) -eq 0)
       {
         "On: " + $on
         if ([System.String]::IsNullOrEmpty($on) -or $todaysDate.Day -eq $on)
         {
           $reopen = $True
         }
       }
     }
     else
     {
       "Unrecognized Since: " + $since
     }
  }
  else
  {
    "Unrecognized unit: " + $unit
  }

  "Reopen: " + $reopen
  if ($reopen)
  {
    $json = "{ `"state`": `"open`" }"
    $result = Invoke-RestMethod -Method PATCH -Headers $Headers -Uri $item.url -Body $json
    $result
  }
}

$LASTEXITCODE = 0
return 0;
