<#
.SYNOPSIS
    Gets ConnectWise ticket information. 
.PARAMETER ID
    ConnectWise ticket ID
.PARAMETER Filter
    Query String 
.PARAMETER BoardID
    ID of the ConnectWise board to retrieve tickets
.PARAMETER Property
    Name of the properties to return
.PARAMETER SizeLimit
    Max number of items to return
.PARAMETER Descending
    Changes the sorting to descending order by IDs
.EXAMPLE
    $CWServer = Set-CWSession -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWServiceTicket -ID 1 -Server $CWServer;
.EXAMPLE
    $CWServer =  -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWServiceTicket -Query "ID in (123, 456, 789, 321, 654, 987)" -Server $CWServer;
#>
function Get-CWServiceTicket 
{
    [CmdLetBinding()]
    [OutputType("PSObject", ParameterSetName="Normal")]
    [OutputType("PSObject[]", ParameterSetName="Query")]
    [OutputType("PSObject[]", ParameterSetName="Summary")]
    [CmdletBinding(DefaultParameterSetName="Normal")]
    param
    (
        [Parameter(ParameterSetName='Normal', Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [int[]]$ID,
        [Parameter(ParameterSetName='Summary', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Summary,
        [Parameter(ParameterSetName='Query', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,
        [Parameter(ParameterSetName='Normal', Position=1, Mandatory=$false)]
        [Parameter(ParameterSetName='Summary', Mandatory=$false)]
        [Parameter(ParameterSetName='Query', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Property,
        [Parameter(ParameterSetName='Summary', Mandatory=$false)]
        [Parameter(ParameterSetName='Query', Mandatory=$false)]
        [ValidateRange(1, 1000)]
        [int]$SizeLimit = 100,
        [Parameter(ParameterSetName='Summary')]
        [Parameter(ParameterSetName='Query')]
        [switch]$Descending,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [Parameter(ParameterSetName='Summary', Mandatory=$false)]
        [Parameter(ParameterSetName='Query', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Session = $script:CWSession
    )
    
    Begin
    {
        $MAX_ITEMS_PER_PAGE = 50;
        [string]$OrderBy = [String]::Empty;
        
        # get the Ticket service
        $TicketSvc = [CwApiServiceTicketSvc]::new($Session);
        
        [uint32] $ticketCount = 1; 
        [uint32] $pageCount   = 1;
        
        # get the number of pages of ticket to request and total ticket count
        if (![String]::IsNullOrWhiteSpace($Filter) -or ![String]::IsNullOrWhiteSpace($Summary))
        {
            if (![String]::IsNullOrWhiteSpace($Summary))
            {
                $Filter = "summary='$Summary'";
                if ([RegEx]::IsMatch($Summary, "\*"))
                {
                    $Filter = "summary like '$Summary'";
                }
                Write-Verbose "Created a Filter String Based on the Summary Value ($Summary): $Filter";
            }
            
            $ticketCount = $TicketSvc.GetTicketCount($Filter);
            Write-Debug "Total Count Ticket the Filter ($Filter): $ticketCount";
            
            if ($SizeLimit -ne $null -and $SizeLimit -gt 0)
            {
                Write-Verbose "Total Ticket Count Excess SizeLimit; Setting Ticket Count to the SizeLimit: $SizeLimit"
                $ticketCount = [Math]::Min($ticketCount, $SizeLimit);
            }
            $pageCount = [Math]::Ceiling([double]($ticketCount / $MAX_ITEMS_PER_PAGE));
            
            Write-Debug "Total Number of Pages ($MAX_ITEMS_PER_PAGE Tickets Per Pages): $pageCount";
        }
        
        if ($Descending)
        {
            $OrderBy = " id desc";
        }
        
        # determines if to select all fields or specific fields
        [string[]] $Properties = $null;
        if ($Property -ne $null)
        {
            if (!($Property.Length -eq 1 -and $Property[0].Trim() -ne "*"))
            {
                # TODO add parser for valid fields only
                $Properties = $Property;
            }
        }
        
    }
    Process
    {
        
        for ($pageNum = 1; $pageNum -le $pageCount; $pageNum++)
        {
            
            if (![String]::IsNullOrWhiteSpace($Filter))
            {
                if ($ticketCount -ne $null -and $ticketCount -gt 0)
                {
                    # find how many Companies to retrieve
                    $itemsRemainCount = $ticketCount - (($pageNum - 1) * $MAX_ITEMS_PER_PAGE);
                    $itemsPerPage = [Math]::Min($itemsRemainCount, $MAX_ITEMS_PER_PAGE);
                } 
                
                Write-Debug "Requesting Ticket IDs that Meets this Filter: $Filter";
                $queriedTickets = $TicketSvc.ReadTickets($Filter, [string[]] @("id"), $OrderBy, $pageNum, $itemsPerPage);
                [uint32[]] $ID = $queriedTickets.id;
            }  
            
            if ($ID -ne $null)
            {
                Write-Debug "Retrieving ConnectWise Tickets by Ticket ID"
                foreach ($ticket in $ID)
                {
                    Write-Verbose "Requesting ConnectWise Ticket Number: $ticket";
                    if ($Properties -eq $null -or $Properties.Length -eq 0)
                    {
                        $TicketSvc.ReadTicket($ticket);
                    }
                    else 
                    {
                        $TicketSvc.ReadTicket($ticket, $Properties);
                    }
                }
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
    Creates a ConnectWise ticket. 
.PARAMETER BoardID
    ID of the ConnectWise board
.PARAMETER CompanyID
    ID of the ConnectWise company
.PARAMETER ContactID
    ID of the contact in ConnectWise 
.PARAMETER Subject
    Subject of the ticket
.PARAMETER Description
    Initial body of the ticket placed in the ticket's Detailed Description section
.PARAMETER Internal
    Initial message of the ticket placed in the ticket's Internal Analysis section
.PARAMETER PriorityID
    ID of the ConnectWise priority
.PARAMETER StatusID
    ID of the ConnectWise board status
.EXAMPLE
    $CWServer = Set-CWSession -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    New-CWServiceTicket -BoardID 1 -CompanyID 7 -ContactID 10 -Subject "My First Ticket" Description "This is my first ticket created via PowerShell." -Server $CWServer;
#>
function New-CWServiceTicket 
{
    [CmdLetBinding()]
    [OutputType("PSObject", ParameterSetName="Normal")]
    param
    (
        [Parameter(ParameterSetName='Normal', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$BoardID,
        [Parameter(ParameterSetName='Normal', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$CompanyID,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [uint32]$ContactID,
        [Parameter(ParameterSetName='Normal', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Subject,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$Description,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$Internal,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [uint32]$PriorityID,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [uint32]$StatusID,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [uint32]$SourceID,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [uint32]$TypeID,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [uint32]$SubTypeID,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [uint32]$ItemID,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$Severity,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$Impact,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Session = $script:CWSession
    )
    
    Begin
    {
        [CwApiServiceTicketSvc] $TicketSvc = $null; 
        
        # get the Ticket service
        if ($Session -ne $null)
        {
            $TicketSvc = [CwApiServiceTicketSvc]::new($Session);
        } 
        else 
        {
            $TicketSvc = [CwApiServiceTicketSvc]::new($Domain, $CompanyName, $PublicKey, $PrivateKey);
        }
    }
    Process
    {
        $newTicket = $TicketSvc.CreateTicket($BoardID, $CompanyID, $ContactID, $Subject, $Description, $Internal, $StatusID, $Severity, $Impact, $SourceID, $PriorityID, $TypeID, $SubTypeID, $ItemID);
        return $newTicket;
    }
    End
    {
        # do nothing here
    }
} 

<#
.SYNOPSIS
    Updates a ConnectWise ticket. 
.PARAMETER ID
    ID of the ConnectWise ticket to update
.PARAMETER BoardID
    New ConnectWise board id for the ticket
.PARAMETER ContactID
    ID of the contact in ConnectWise 
.PARAMETER Subject
    New ConnectWise ticket subject
.PARAMETER Message
    New message to be added to Detailed Description, Internal Analysis, and/or Resolution section
.PARAMETER AddToDescription
    Instructs the value of `-Message` to the Detailed Description
.PARAMETER AddToInternal
    Instructs the value of `-Message` to the Internal Analysis
.PARAMETER AddToResolution
    Instructs the value of `-Message` to the Resolution
.PARAMETER PriorityID
    New ConnectWise priority id for the ticket
.PARAMETER StatusID
    New ConnectWise status id for the ticket 
.EXAMPLE
    $CWServer = Set-CWSession -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Update-CWServiceTicket -ID 123 -StatusID 11 -Message "Changed the ticket status and added ticket note added to ticket via PowerShell." -Server $CWServer;
#>
function Update-CWServiceTicket
{
    [CmdLetBinding()]
    [OutputType("PSObject", ParameterSetName="Normal")]
    param
    (
        [Parameter(ParameterSetName='Normal', Mandatory=$true)]
        [Parameter(ParameterSetName='WithMessage', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$ID,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [Parameter(ParameterSetName='WithMessage', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [uint32]$BoardID,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [Parameter(ParameterSetName='WithMessage', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [uint32]$ContactID,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [Parameter(ParameterSetName='WithMessage', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$Subject,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [Parameter(ParameterSetName='WithMessage', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [uint32]$PriorityID,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [Parameter(ParameterSetName='WithMessage', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [uint32]$StatusID,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [Parameter(ParameterSetName='WithMessage', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        [Parameter(ParameterSetName='WithMessage', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [switch]$AddToDescription,
        [Parameter(ParameterSetName='WithMessage', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [switch]$AddToInternal,
        [Parameter(ParameterSetName='WithMessage', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [switch]$AddToResolution,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [Parameter(ParameterSetName='WithMessage', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Session = $script:CWSession
    )
    
    Begin
    {
        [CwApiServiceTicketSvc] $TicketSvc = $null; 
        [CwApiServiceTicketNoteSvc] $NoteSvc = $null; 
        
        # get the Ticket service
        if ($Session -ne $null)
        {
            $TicketSvc = [CwApiServiceTicketSvc]::new($Session);
            $NoteSvc = [CwApiServiceTicketNoteSvc]::new($Session);
        } 
        else 
        {
            $TicketSvc = [CwApiServiceTicketSvc]::new($Domain, $CompanyName, $PublicKey, $PrivateKey);
            $NoteSvc   = [CwApiServiceTicketNoteSvc]::new($Domain, $CompanyName, $PublicKey, $PrivateKey);
        }
        
        [CWServiceTicketNoteTypes[]] $addToForNote = @();
        if ($AddToDescription -eq $false -and $AddToInternal -eq $false -and $AddToResolution -eq $false)
        {
            # defaults to detail description if no AddTo switch were passed
            $AddToDescription = $true
        }
        
        if ($AddToDescription -eq $true)
        {
            $addToForNote += [CWServiceTicketNoteTypes]::Description;
        }
        if ($AddToInternal -eq $true)
        {
            $addToForNote += [CWServiceTicketNoteTypes]::Internal;
        }
        if ($AddToResolution -eq $true)
        {
            $addToForNote += [CWServiceTicketNoteTypes]::Resolution;
        }  
    }
    Process
    {
        #create a ticket note
        if (![String]::IsNullOrWhiteSpace($Message))
        {
            $note = $NoteSvc.CreateNote($ID, $Message, $addToForNote);
            
            if (!$note.id -gt 0)
            {
                Write-Error "Failed to add ticket note."
            }
        }
        
        #update the ticket
        if ($BoardID -gt 0 -or $ContactID -gt 0 -or $StatusID -gt 0 -or $PriorityID -gt 0 -or ![String]::IsNullOrEmpty($Subject))
        {
            return $TicketSvc.UpdateTicket($ID, $BoardID, $ContactID, $StatusID, $PriorityID, $Subject);
        }
        else
        {
            return $TicketSvc.ReadTicket($ID);
        }    
    }
    End
    {
        # do nothing here
    }
    
}

<#
.SYNOPSIS
    Removes ConnectWise ticket information. 
.PARAMETER ID
    ConnectWise ticket ID
.PARAMETER Server
    Variable to the object created via Get-CWConnectWiseInfo
.EXAMPLE
    $CWServer = Set-CWSession -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Remove-CWServiceTicket -ID 1 -Server $CWServer;
#>
function Remove-CWServiceTicket 
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact="Medium")]  
    [OutputType("Boolean", ParameterSetName="Normal")]
    param
    (
        [Parameter(ParameterSetName='Normal', Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [int[]]$ID,
        [Parameter(ParameterSetName='Normal', Position=1, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Session = $script:CWSession
    )
    
    Begin
    {
        [CwApiServiceTicketSvc] $TicketSvc = $null; 
        
        # get the service
        $TicketSvc = $null;
        if ($Session -ne $null)
        {
            $TicketSvc = [CwApiServiceTicketSvc]::new($Session);
        } 
        else 
        {
            Write-Error "No open ConnectWise session. See Set-CWSession for more information.";
        }
        
    }
    Process
    {
        Write-Debug "Deleting ConnectWise Tickets by Ticket ID"
        foreach ($ticket in $ID)
        {
            if ($Force -or $PSCmdlet.ShouldProcess($entry))
            {
                $TicketSvc.DeleteTicket($ticket);
            }
            else 
            {

            }
        }
    }
    End 
    {
        # do nothing here
    }
}

Export-ModuleMember -Function 'Get-CWServiceTicket';
Export-ModuleMember -Function 'New-CWServiceTicket';
Export-ModuleMember -Function 'Update-CWServiceTicket';
Export-ModuleMember -Function 'Remove-CWServiceTicket';
