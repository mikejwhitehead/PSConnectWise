#dot-source import the classes
. "$PSScriptRoot\PSCWApiClasses.ps1"

function Get-CWServiceTicketTimeEntry
{
    [CmdLetBinding()]
    param
    (
        [Parameter(ParameterSetName='TicketTimeEntries', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [int32]$TicketID,
        [Parameter(ParameterSetName='TicketTimeEntries', Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$BaseApiUrl,
        [Parameter(ParameterSetName='TicketTimeEntries', Position=2, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$CompanyName,
        [Parameter(ParameterSetName='TicketTimeEntries', Position=3, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PublicKey,
        [Parameter(ParameterSetName='TicketTimeEntries', Position=4, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PrivateKey
    )
    
    Begin
    {
        $MAX_ITEMS_PER_PAGE = 50;
        
        # get the TimeEntry service
        $TimeEntrySvc = [CwApiServiceTicketTimeEntrySvc]::new($BaseApiUrl, $CompanyName, $PublicKey, $PrivateKey);
        
        [uint32] $timeEntryCount = $MAX_ITEMS_PER_PAGE;
        [uint32] $pageCount  = 1;
        
        # get the number of pages of ticket to request and total ticket count
        if ([String]::IsNullOrWhiteSpace($EntryID))
        {
            $timeEntryCount = $TimeEntrySvc.GetTimeEntryCount($TicketID);
            Write-Debug "Total Count of Time Entries for Ticket ($TicketID): $timeEntryCount";
            
            if ($SizeLimit -ne $null -and $SizeLimit -gt 0)
            {
                Write-Verbose "Total Ticket Time Entry Count Excess SizeLimit; Setting Ticket Time Entry Count to the SizeLimit: $SizeLimit"
                $timeEntryCount = [Math]::Min($timeEntryCount, $SizeLimit);
            }
            $pageCount = [Math]::Ceiling([double]($timeEntryCount / $MAX_ITEMS_PER_PAGE));
            
            Write-Debug "Total Number of Pages ($MAX_ITEMS_PER_PAGE Ticket Time Entry Per Pages): $pageCount";
        }
    }
    Process
    {
        
        for ($pageNum = 1; $pageNum -le $pageCount; $pageNum++)
        {
            if ([String]::IsNullOrWhiteSpace($EntryID))
            {
                # find how many boards to retrieve
                $itemsPerPage = $timeEntryCount - (($pageNum - 1) * $MAX_ITEMS_PER_PAGE);
                
                Write-Debug "Requesting Time Entries for Ticket: $TicketID";
                $queriedTimeEntries = $TimeEntrySvc.ReadTimeEntries($TicketID, $pageNum, $itemsPerPage);
                [pscustomobject[]] $TimeEntries = $queriedTimeEntries;
            
            } else {
                
                $TimeEntries = $TimeEntrySvc.ReadTimeEntry($TicketID, $EntryID);
            
            } 
            
            foreach ($TimeEntry in $TimeEntries)
            {
                Write-Verbose "Requesting ConnectWise Time Entry Number: $($TimeEntry.id)";
                $TimeEntry;
            } 
                
        }
    }
    End
    {
        # do nothing here
    }
}

Export-ModuleMember -Function 'Get-CWServiceTicketTimeEntry';