#dot-source import the classes
. "$PSScriptRoot\PSCWApiClasses.ps1"

function Get-CWServiceTicketNote
{
    [CmdLetBinding()]
    param
    (
        [Parameter(ParameterSetName='TicketNotes', Position=0, Mandatory=$true)]
        [Parameter(ParameterSetName='SingleNote', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [int32]$TicketID,
        [Parameter(ParameterSetName='SingleNote', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [int32]$NoteID,
        [Parameter(ParameterSetName='TicketNotes', Position=1, Mandatory=$true)]
        [Parameter(ParameterSetName='SingleNote', Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$BaseApiUrl,
        [Parameter(ParameterSetName='TicketNotes', Position=1, Mandatory=$true)]
        [Parameter(ParameterSetName='SingleNote', Position=2, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$CompanyName,
        [Parameter(ParameterSetName='TicketNotes', Position=1, Mandatory=$true)]
        [Parameter(ParameterSetName='SingleNote', Position=3, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PublicKey,
        [Parameter(ParameterSetName='TicketNotes', Position=1, Mandatory=$true)]
        [Parameter(ParameterSetName='SingleNote', Position=4, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PrivateKey
    )
    
    Begin
    {
        $MAX_ITEMS_PER_PAGE = 50;
        
        # get the TimeEntry service
        $NoteSvc = [CwApiServiceTicketNoteSvc]::new($BaseApiUrl, $CompanyName, $PublicKey, $PrivateKey);
        
        [uint32] $noteCount = $MAX_ITEMS_PER_PAGE;
        [uint32] $pageCount  = 1;
        
        # get the number of pages of ticket to request and total ticket count
        if (![String]::IsNullOrWhiteSpace($TicketID))
        {
            $noteCount = $NoteSvc.GetNoteCount($TicketID);
            Write-Debug "Total Count of Ticket Note Entries for Ticket ($TicketID): $noteCount";
            
            if ($SizeLimit -ne $null -and $SizeLimit -gt 0)
            {
                Write-Verbose "Total Ticket Notes Count Excess SizeLimit; Setting Ticket Note Count to the SizeLimit: $SizeLimit"
                $noteCount = [Math]::Min($noteCount, $SizeLimit);
            }
            $pageCount = [Math]::Ceiling([double]($noteCount / $MAX_ITEMS_PER_PAGE));
            
            Write-Debug "Total Number of Pages ($MAX_ITEMS_PER_PAGE Ticket Notes Per Pages): $pageCount";
        }
    }
    Process
    {
        
        for ($pageNum = 1; $pageNum -le $pageCount; $pageNum++)
        {
            if ($NoteID -eq 0)
            {
                # find how many notes a ticket has to retrieve
                $itemsPerPage = $noteCount - (($pageNum - 1) * $MAX_ITEMS_PER_PAGE);
                
                Write-Debug "Requesting Note Entries for Ticket: $TicketID";
                $queriedNotes = $NoteSvc.ReadNotes($TicketID, $pageNum, $itemsPerPage);
                [pscustomobject[]] $Notes = $queriedNotes;
            
            } else {
                
                $Notes = $NoteSvc.ReadNote($TicketID, $NoteID);
          
            } 
            
            foreach ($Note in $Notes)
            {

                Write-Verbose "Requesting ConnectWise Ticket Note Number: $($Note.id)";
                $Note;
            } 
                
        }
    }
    End
    {
        # do nothing here
    }
}

function Add-CWServiceTicketNote 
{
    [CmdLetBinding()]
    param
    (
        [Parameter(ParameterSetName='Normal', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$TicketID,
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
        [Parameter(ParameterSetName='Normal', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$BaseApiUrl,
        [Parameter(ParameterSetName='Normal', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$CompanyName,
        [Parameter(ParameterSetName='Normal', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PublicKey,
        [Parameter(ParameterSetName='Normal', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PrivateKey
    )
    
    Begin
    {
        # get the ticket service
        $NoteSvc = [CwApiServiceTicketNoteSvc]::new($BaseApiUrl, $CompanyName, $PublicKey, $PrivateKey);
        
        [ServiceTicketNoteTypes[]] $addTo = @();
        
        if ($AddToDescription -eq $false -and $AddToInternal -eq $false -and $AddToResolution -eq $false)
        {
            # defaults to detail description if no AddTo switch were passed
            $AddToDescription = $true
        }
        
        if ($AddToDescription -eq $true)
        {
            $addTo += [ServiceTicketNoteTypes]::Description;
        }
        if ($AddToInternal -eq $true)
        {
            $addTo += [ServiceTicketNoteTypes]::Internal;
        }
        if ($AddToResolution -eq $true)
        {
            $addTo += [ServiceTicketNoteTypes]::Resolution;
        }   
    }
    Process
    {
        $newNote = $NoteSvc.CreateNote($TicketID, $Message, $addTo);
        return $newNote;
    }
    End
    {
        # do nothing here
    }
} 

Export-ModuleMember -Function 'Get-CWServiceTicketNote';
Export-ModuleMember -Function 'Add-CWServiceTicketNote';