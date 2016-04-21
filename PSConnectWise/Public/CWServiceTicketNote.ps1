<#
.SYNOPSIS
    Gets notes/messsage of a ConnectWise ticket. 
.PARAMETER TicketID
    ConnectWise ticket ID
.PARAMETER NoteID
    ConnectWise ticket note ID
.PARAMETER Server
    Variable to the object created via Get-CWConnectWiseInfo
.EXAMPLE
    $CWServer = Get-CWConnectionInfo -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWCompanyContact -ID 1 -Server $CWServer;
.EXAMPLE
    $CWServer = Get-CWConnectionInfo -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWServiceTicketNote -TicketID 123 -Server $CWServer;
#>
function Get-CWServiceTicketNote
{
    [CmdLetBinding()]
    [OutputType("PSObject", ParameterSetName="Normal")]
    [OutputType("PSObject", ParameterSetName="Single")]
    param
    (
        [Parameter(ParameterSetName='Normal', Position=0, Mandatory=$true)]
        [Parameter(ParameterSetName='Single', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [int32]$TicketID,
        [Parameter(ParameterSetName='Single', Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [int32]$NoteID,
        [Parameter(ParameterSetName='Normal', Position=1, Mandatory=$true)]
        [Parameter(ParameterSetName='Single', Position=2, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Server
    )
    
    Begin
    {
        $MAX_ITEMS_PER_PAGE = 50;
        [CwApiServiceTicketNoteSvc] $NoteSvc = $null; 
        
        # get the Note service
        if ($Server -ne $null)
        {
            $NoteSvc = [CwApiServiceTicketNoteSvc]::new($Server);
        } 
        else 
        {
            $NoteSvc = [CwApiServiceTicketNoteSvc]::new($Domain, $CompanyName, $PublicKey, $PrivateKey);
        }
        
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
                
                if ($noteCount -ne $null -and $noteCount -gt 0)
                {
                    # find how many Companies to retrieve
                    $itemsLeftToRetrived = $noteCount - (($pageNum - 1) * $MAX_ITEMS_PER_PAGE);
                    $itemsPerPage = [Math]::Min($itemsLeftToRetrived, $MAX_ITEMS_PER_PAGE);
                }  
                
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

<#
.SYNOPSIS
    Adds a new note to a ConnectWise ticket. 
.PARAMETER Ticket
    ID of the ConnectWise ticket to update
.PARAMETER Message
    New message to be added to Detailed Description, Internal Analysis, and/or Resolution section
.PARAMETER AddToDescription
    Instructs the value of `-Message` to the Detailed Description
.PARAMETER AddToInternal
    Instructs the value of `-Message` to the Internal Analysis
.PARAMETER AddToResolution
    Instructs the value of `-Message` to the Resolution
.EXAMPLE
    $CWServer = Get-CWConnectionInfo -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Add-CWServiceTicketNote -ID 123 -Message "Added ticket note added to ticket via PowerShell." -Server $CWServer;
#>
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
        [Parameter(ParameterSetName='Normal', Position=2)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Server
    )
    
    Begin
    {
        [CwApiServiceTicketNoteSvc] $NoteSvc = $null; 
        
        # get the Note service
        if ($Server -ne $null)
        {
            $NoteSvc = [CwApiServiceTicketNoteSvc]::new($Server);
        } 
        else 
        {
            $NoteSvc = [CwApiServiceTicketNoteSvc]::new($Domain, $CompanyName, $PublicKey, $PrivateKey);
        }
        
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