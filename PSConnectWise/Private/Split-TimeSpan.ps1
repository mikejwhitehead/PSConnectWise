<#
.SYNOPSIS
    Split a time span in to seperate entries.
.DESCRIPTION
    Splits the time between the start and end TimeDate in to seperate entries per day. It returns array of hashtables with start and end time for that day.  
.PARAMETER Start
    Start date and time of the spanned time
.PARAMETER End
    End date and time of the spanned time
.PARAMETER UniveralTime
    Use and return all dates and times to Universal time
.EXAMPLE
    $started = (Get-Date).AddHours(-36);
    $ended   = Get-Date;
    Split-TimeSpan -Start $started -End $ended;
.EXAMPLE
    $started = (Get-Date).AddHours(-76);
    $ended   = Get-Date;
    Split-TimeSpan -Start $started -End $ended -UniveralTime;
#>
function Split-TimeSpan
{
    [CmdLetBinding()]
    [OutputType("hashtable[]", ParameterSetName="Normal")]
    [CmdletBinding(DefaultParameterSetName="Normal")]
    param
    (   
        [Parameter(ParameterSetName='Normal', Position=0, Mandatory=$true)]
        [DateTime]$Start,
        [Parameter(ParameterSetName='Normal', Position=1, Mandatory=$true)]
        [DateTime]$End,
        [Parameter(ParameterSetName='Normal')]
        [Switch]$UniversalTime
    )
    
    if ($UniveralTime)
    {
        $Start = $Start.ToUniversalTime();
        $End   = $End.ToUniversalTime();
    }

    [hashtable[]] $SplitedTimeEntries  = @();        

    if ($Start -gt $End)
    {
        throw [System.ArgumentOutOfRangeException]::new("Start TimeDate must be after the End TimeDate.")
    }
    
    $days = $End.Date.Subtract($Start.Date).Days
    for ($day = 0; $day -le $days; $day++)
    {
        if ($day -eq 0 -and $days -eq 0)
        {
            # starts and ends on the same day
            $SplitedTimeEntries += [hashtable] @{
                Start = $Start;
                End   = $End;
            }
        }
        elseif ($day -eq 0)
        {
            # first entry when start and end is not on the same day
            $SplitedTimeEntries += [hashtable] @{
                Start = $Start;
                End   = $Start.AddDays(1).Date.AddSeconds(-1);
            }
        }
        elseif ($day -gt 0 -and $day -ne $days)
        {
            # neither the first or last entry when start and end is not on the same day
            $SplitedTimeEntries += [hashtable] @{
                Start = $Start.AddDays($day).Date;
                End   = $Start.AddDays($day + 1).AddSeconds(-1).Date;
            }
        }
        else
        {
            # last entry when start and end is not on the same day
            $SplitedTimeEntries += [hashtable] @{
                Start = $Start.AddDays($day).Date;
                End   = $End;
            }
        }
    }

    return $SplitedTimeEntries;
}

Export-ModuleMember -Function 'Split-TimeSpan';