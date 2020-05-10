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
  $startDate = $createdDate
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
  $foundMetdata = $false
  while ($True)
  {
    $line = $reader.ReadLine();
    if ($line -eq $null)
    {
        break;
    }
    
    if ($line.Equals("#### Recurrence Schedule"))
    {
        $foundMetdata = $true
        continue;
    }

    if (!$foundMetdata)
    {
        continue;
    }
    
    $lineWords = $line.Split(' ');

    if ($lineWords.Count -le 1)
    {
        # Not a "key: value" pair, skip
    }
    # Every
    if ([System.String]::Equals($lineWords[0], "Every:", [System.StringComparison]::OrdinalIgnoreCase))
    {
        $every = $lineWords[1];
    }
    # Unit
    elseif ([System.String]::Equals($lineWords[0], "Unit:", [System.StringComparison]::OrdinalIgnoreCase))
    {
        $unit = $lineWords[1];
    }
    # Since
    elseif ([System.String]::Equals($lineWords[0], "Since:", [System.StringComparison]::OrdinalIgnoreCase))
    {
        $since = $lineWords[1];
    }
    # On
    elseif ([System.String]::Equals($lineWords[0], "On:", [System.StringComparison]::OrdinalIgnoreCase))
    {
        $on = $lineWords[1];
    }
    # Start
    elseif ([System.String]::Equals($lineWords[0], "Start:", [System.StringComparison]::OrdinalIgnoreCase))
    {
        $start = $lineWords[1];
        $startDate = [System.DateTime]::Parse($start)
    }
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
       $days = ($todaysDate - $startDate).TotalDays
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
       [int] $weeks = [System.Math]::Floor(($todaysDate - $startDate).TotalDays / 7)
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
       $months = (($todaysDate.Year - $startDate.Year) * 12) + ($todaysDate.Month - $startDate.Month)
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
