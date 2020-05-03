# Query for closed recurring issues
$Headers = @{ Authorization = 'token {0}' -f $ENV:GITHUB_TOKEN; };
$result = Invoke-RestMethod -Headers $Headers -Uri "https://api.github.com/repos/Tratcher/SharedTasks/issues?state=closed&labels=Recurring"
ForEach ($item in $result)
{
 $item.title
 $lines = $item.body.Split("`r`n", [System.StringSplitOptions]::RemoveEmptyEntries);
 $lines
 $type = "";
 $every = "";
 $on = "";
 for ($i = 0; $i -lt $lines.Count; $i++)
 {
   $line = $lines[$i];
   if ($line.Equals("#### Recurrence Schedule"))
   {
     if (($i + 1) -lt $lines.Count)
     {
       $typeLineWords = $lines[$i + 1].Split(' ');
       if ($typeLineWords.Count -gt 1 -and [System.String]::Equals($typeLineWords[0], "Type:", [System.StringComparison]::OrdinalIgnoreCase))
       {
         $type = $typeLineWords[1];
       }
     }

     if (($i + 2) -lt $lines.Count)
     {
       $everyLineWords = $lines[$i + 2].Split(' ');
       if ($everyLineWords.Count -gt 1 -and [System.String]::Equals($everyLineWords[0], "Every:", [System.StringComparison]::OrdinalIgnoreCase))
       {
         $every = $everyLineWords[1];
       }
     }

     if (($i + 3) -lt $lines.Count)
     {
       $onLineWords = $lines[$i + 3].Split(' ');
       if ($onLineWords.Count -gt 1 -and [System.String]::Equals($onLineWords[0], "On:", [System.StringComparison]::OrdinalIgnoreCase))
       {
         $on = $onLineWords[1];
       }
     }
     break;
   }
 }

 if ([System.String]::Equals($type, "Daily", [System.StringComparison]::OrdinalIgnoreCase))
 {
    $type
 }
 elseif ([System.String]::Equals($type, "Weekly", [System.StringComparison]::OrdinalIgnoreCase))
 {
    $type
    $every
    $on
 }
 elseif ([System.String]::Equals($type, "Monthly", [System.StringComparison]::OrdinalIgnoreCase))
 {
    $type
    $every
    $on
 }
 else
 {
   $message = "Unrecognized type: " + $type
   $message
 }
}
