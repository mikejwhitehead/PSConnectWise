<#
.SYNOPSIS
    Gets time entries of a ConnectWise ticket. 
.PARAMETER TicketID
    ConnectWise ticket ID
.PARAMETER ID
    ConnectWise ticket note ID
.PARAMETER Detailed
    Retrieves detailed time entry data
.PARAMETER Descending
    Changes the sorting to descending order by IDs
.PARAMETER Server
    Variable to the object created via Get-CWConnectWiseInfo.
.EXAMPLE
    Get-CWTimeEntry -ID 99;
.EXAMPLE
    Get-CWTimeEntry -TicketID 123 -Descending;
#>
function Get-CWTimeEntry
{
    [CmdLetBinding()]
    [OutputType("PSObject[]", ParameterSetName="Normal")]
    [OutputType("PSObject", ParameterSetName="Single")]
    [CmdletBinding(DefaultParameterSetName="Normal")]
    param
    (
        [Parameter(ParameterSetName='Single', Position=1, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$ID,
        [Parameter(ParameterSetName='Normal', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$TicketID,
        [Parameter(ParameterSetName='Normal')]
        [ValidateNotNullOrEmpty()]
        [uint32]$SizeLimit = 0,
        [Parameter(ParameterSetName='Normal')]
        [switch]$Detailed,
        [Parameter(ParameterSetName='Normal')]
        [switch]$Descending,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [Parameter(ParameterSetName='Single', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Session = $script:CWSession
    )
    
    Begin
    {
        $MAX_ITEMS_PER_PAGE = 25;
        [string]$OrderBy = [String]::Empty;
        
        # get the TimeEntry service
        $TimeSvc = [CwApiTimeEntrySvc]::new($Session);
        
        [uint32] $entryCount = $MAX_ITEMS_PER_PAGE;
        [uint32] $pageCount  = 1;
        
        # get the number of pages of time entries to request and total entry count
        if ($null -ne $TicketID -and $TicketID -gt 0)
        {
            $entryCount = $TimeSvc.GetTimeEntryCount($TicketID);
            Write-Debug "Total Count of Ticket Time Entries for Ticket ($TicketID): $entryCount";
            
            if ($null -ne $SizeLimit -and $SizeLimit -gt 0)
            {
                Write-Verbose "Total Ticket Entry Count Excess SizeLimit; Setting Entry Note Count to the SizeLimit: $SizeLimit"
                $entryCount = [Math]::Min($entryCount, $SizeLimit);
            }
            $pageCount = [Math]::Ceiling([double]($entryCount / $MAX_ITEMS_PER_PAGE));
            
            Write-Debug "Total Number of Pages ($MAX_ITEMS_PER_PAGE Ticket Entry Per Pages): $pageCount";
        }
        
        #specify the ordering
        if ($Descending)
        {
            $OrderBy = " id desc";
        }
    }
    Process
    {
        for ($pageNum = 1; $pageNum -le $pageCount; $pageNum++)
        {
            
            if ($ID -eq 0 -and $Detailed -eq $true)
            {
                Write-Debug "Requesting Full Note Entries for Ticket: $TicketID";
                $queriedTimeEntries = $TimeSvc.ReadTimeEntries($TicketID, $pageNum, $MAX_ITEMS_PER_PAGE);
                [psobject[]] $Entries = $queriedTimeEntries;
            
            } elseif ($ID -eq 0 -and $Detailed -ne $true) {

                Write-Debug "Requesting Basic Note Entries for Ticket: $TicketID";
                $queriedTimeEntries = $TimeSvc.ReadBasicTimeEntries($TicketID, $pageNum, $MAX_ITEMS_PER_PAGE);
                [psobject[]] $Entries = $queriedTimeEntries;

            } else {
                
                Write-Verbose "Requesting ConnectWise Time Entry for Ticket Number: $($Entry.id)";
                $Entries = $TimeSvc.ReadTimeEntry($ID);
          
            } 
                
        }

        foreach ($Entry in $Entries)
        {
            $Entry;
        }
    }
    End
    {
        # do nothing here
    }
}

<#
.SYNOPSIS
    Adds a new note to a ConnectWise ticket. 
.PARAMETER TicketID
    ID of the ConnectWise ticket to update
.PARAMETER Start
    Start time and date of the time entry
.PARAMETER End
    End time and date of the time entry
.PARAMETER Message
    New message to be added to Detailed Description, Internal Analysis, and/or Resolution section.
.PARAMETER AddToDescription
    Instructs the value of `-Message` to the Detailed Description
.PARAMETER AddToInternal
    Instructs the value of `-Message` to the Internal Analysis
.PARAMETER AddToResolution
    Instructs the value of `-Message` to the Resolution
.PARAMETER InternalNote
    Note to be added to the hidden Internal Note field 
.PARAMETER ChargeToType
    Change to type of the time entry
.PARAMETER BillOption
   Type of billing for the time entry
.PARAMETER CompanyID
    Company to charge the time entry against
.PARAMETER MemberID
    ConnectWise memeber ID of the CW user the time entry should be applied against
.EXAMPLE
    $CWServer = Set-CWSession -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Add-CWTimeEntry -ID 123 -Message "Added ticket note added to ticket via PowerShell." -Server $CWServer;
#>
function Add-CWTimeEntry 
{
    [CmdLetBinding()]
    [OutputType("PSObject[]", ParameterSetName="Normal")]
    [CmdletBinding(DefaultParameterSetName="Normal")]
    param
    (
        [Parameter(ParameterSetName='Normal', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$TicketID,
        [Parameter(ParameterSetName='Normal', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [DateTime]$Start,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [DateTime]$End = (Get-Date),
        [Parameter(ParameterSetName='Normal', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [switch]$AddToDescription,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [switch]$AddToInternal,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [switch]$AddToResolution,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$InternalNote,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateSet('ServiceTicket', 'ProjectTicket', 'ChargeCode', 'Activity')]
        [ValidateNotNullOrEmpty()]
        [string]$ChargeToType = "ServiceTicket",
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateSet('Billable', 'DoNotBill', 'NoCharge', 'NoDefault')]
        [ValidateNotNullOrEmpty()]
        [string]$BillOption = "DoNotBill",
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [uint32]$CompanyID = 0,
        [Parameter(ParameterSetName='Normal', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$MemberID = 0,
        [Parameter(ParameterSetName='Hash', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$HashTimeEntry,
        [Parameter(ParameterSetName='Normal')]
        [Parameter(ParameterSetName='Hash')]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Session = $script:CWSession
    )
    
    Begin
    {
        [CwApiTimeEntrySvc] $TimeSvc = $null;
        
        # get the Note service
        if ($Session -ne $null)
        {
            $TimeSvc = [CwApiTimeEntrySvc]::new($Session);
        } 
    }
    Process
    {
        [CWServiceTicketNoteTypes[]] $addTo = @();
        
        if ($null -ne $HashTimeEntry)
        {
            $data = $HashTimeEntry;

            $data.BillOption   = @{ $true = $HashTimeEntry.BillOption; $false = "DoNotBill"}[ !$([String]::IsNullOrEmpty($HashTimeEntry.BillOption)) ]
            $data.ChargeToType = @{ $true = $HashTimeEntry.ChargeToType; $false = "ServiceTicket"}[ !$([String]::IsNullOrEmpty($HashTimeEntry.ChargeToType)) ]
            
            $data.AddTo        = @();

            if ("Description" -in $HashTimeEntry.AddTo)
            {
                $data.AddTo += [CWServiceTicketNoteTypes]::Description;
            }
            if ("Internal" -in $HashTimeEntry.AddTo)
            {
                $data.AddTo += [CWServiceTicketNoteTypes]::Internal;
            }
            if ("Resolution" -in $HashTimeEntry.AddTo)
            {
                $data.AddTo += [CWServiceTicketNoteTypes]::Resolution;
            }

            if ($data.AddTo.Count -eq 0)
            {
                # defaults to detail description if no AddTo switch were passed
                $data.AddTo += [CWServiceTicketNoteTypes]::Internal;
            }
        }
        else 
        {

            if ($AddToDescription -eq $false -and $AddToInternal -eq $false -and $AddToResolution -eq $false)
            {
                # defaults to detail description if no AddTo switch were passed
                $AddToDescription = $true
            }
            
            if ($AddToDescription -eq $true)
            {
                $addTo += [CWServiceTicketNoteTypes]::Description;
            }
            if ($AddToInternal -eq $true)
            {
                $addTo += [CWServiceTicketNoteTypes]::Internal;
            }
            if ($AddToResolution -eq $true)
            {
                $addTo += [CWServiceTicketNoteTypes]::Resolution;
            }  

            [hashtable] $data = @{
                TicketID      = $TicketID;
                Start         = $Start;
                End           = $End;
                Message       = $Message;
                AddTo         = $AddTo;
                InternalNotes = $InternalNote;
                CompanyID     = $CompanyID;
                MemberID      = $MemberID;
                ChargeToType  = $ChargeToType;
                BillOption    = $BillOption;
            }
        }

        $newTimeEntries = $TimeSvc.CreateTimeEntry($data);
        return $newTimeEntries;
    }
    End
    {
        # do nothing here
    }
}

<#
.SYNOPSIS
    Updates a ConnectWise TimeEntry. 
.PARAMETER ID
    ID of the ConnectWise TimeEntry to update
.PARAMETER Start
    Start time and date of the time entry
.PARAMETER End
    End time and date of the time entry
.PARAMETER Message
    New message to be added to Detailed Description, Internal Analysis, and/or Resolution section
.PARAMETER InternalNote
    Note to be added to the hidden Internal Note field 
.EXAMPLE
    $CWServer = Set-CWSession -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Update-CWTimeEntry -ID 123 -Message "Changed the TimeEntry status using PowerShell" -Server $CWServer;
#>
function Update-CWTimeEntry
{
    [CmdLetBinding()]
    [OutputType("PSObject", ParameterSetName="Normal")]
    param
    (
        [Parameter(ParameterSetName='Normal', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$ID,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [datetime]$Start,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [datetime]$End,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$InternalNote,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [uint32]$Member,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Session = $Script:CWSession
    )
    
    Begin
    {
        # get the service
        $TimeEntrySvc = $null;
        if ($Session -ne $null)
        {
            $TimeEntrySvc = [CwApiTimeEntrySvc]::new($Session);
        } 
        else 
        {
            Write-Error "No open ConnectWise session. See Set-CWSession for more information.";
        }
    }
    Process
    {
        return $TimeEntrySvc.UpdateTimeEntry($ID, $Start, $End, $Message, $InternalNote, $Member);
    }
    End
    {
        # do nothing here
    }
    
}

<#
.SYNOPSIS
    Removes ConnectWise time entry information. 
.PARAMETER ID
    ConnectWise time entry ID
.PARAMETER Force
    Removes time entry without confirmation prompt
.PARAMETER Server
    Variable to the object created via Get-CWConnectWiseInfo
.NOTES
    ConnectWise API-Only Members do not have access to delete time entries. Therefore, this function will not work for API only members. 
.EXAMPLE
    Remove-CWTimeEntry -ID 1;
#>
function Remove-CWTimeEntry 
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact="Medium")]   
    [OutputType("Boolean", ParameterSetName="Normal")]
    param
    (
        [Parameter(ParameterSetName='Normal', Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [int[]]$ID,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [switch]$Force,        
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Session = $script:CWSession
    )
    
    Begin
    {
        [CwApiTimeEntrySvc] $TimeEntrySvc = $null; 
        
        # get the Ticket service
        if ($Session -ne $null)
        {
            $TimeEntrySvc = [CwApiTimeEntrySvc]::new($Session);
        }
        else
        {
            Write-Error "No open ConnectWise session";
        }
    }
    Process
    {
        Write-Debug "Deleting ConnectWise Time Entries by Ticket ID"
        
        foreach ($entry in $ID)
        {
            if ($Force -or $PSCmdlet.ShouldProcess($entry))
            {
                return $TimeEntrySvc.DeleteTimeEntry($entry);
            }
            else
            {
                return $true;
            }
        }
    }
    End 
    {
        # do nothing here
    }
}

Export-ModuleMember -Function 'Get-CWTimeEntry';
Export-ModuleMember -Function 'Add-CWTimeEntry';
Export-ModuleMember -Function 'Update-CWTimeEntry';
Export-ModuleMember -Function 'Remove-CWTimeEntry';