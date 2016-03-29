#dot-source import the classes
. "$PSScriptRoot\PSCWApiClasses.ps1"

function Get-CWServiceTicket 
{
    [CmdLetBinding()]
    param
    (
        [Parameter(ParameterSetName='SingleTicket', Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [int[]]$TicketID,
        [Parameter(ParameterSetName='TicketQuery', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,
        [Parameter(ParameterSetName='SingleTicket', Position=1, Mandatory=$false)]
        [Parameter(ParameterSetName='TicketQuery', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Property,
        [Parameter(ParameterSetName='TicketQuery', Mandatory=$false)]
        [int]$SizeLimit,
        [Parameter(ParameterSetName='SingleTicket', Position=2, Mandatory=$true)]
        [Parameter(ParameterSetName='TicketQuery', Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$BaseApiUrl,
        [Parameter(ParameterSetName='SingleTicket', Position=3, Mandatory=$true)]
        [Parameter(ParameterSetName='TicketQuery', Position=2, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$CompanyName,
        [Parameter(ParameterSetName='SingleTicket', Position=4, Mandatory=$true)]
        [Parameter(ParameterSetName='TicketQuery', Position=3, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PublicKey,
        [Parameter(ParameterSetName='SingleTicket', Position=5, Mandatory=$true)]
        [Parameter(ParameterSetName='TicketQuery', Position=4, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PrivateKey
    )
    
    Begin
    {
        $MAX_ITEMS_PER_PAGE = 50 
        
        # get the ticket service
        $TicketSvc = [CwApiServiceTicketSvc]::new($BaseApiUrl, $CompanyName, $PublicKey, $PrivateKey);
        
        [uint32] $ticketCount = 1  
        [uint32] $pageCount   = 1  
        
        # get the number of pages of ticket to request and total ticket count
        if (![String]::IsNullOrWhiteSpace($Filter))
        {
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
                # find how many tickets to retrieve
                $ticketsPerPage = $ticketCount - (($pageNum - 1) * $MAX_ITEMS_PER_PAGE);
                
                Write-Debug "Requesting Ticket IDs that Meets this Filter: $Filter";
                $queriedTickets = $TicketSvc.ReadTickets($Filter, [string[]] @("id"), $pageNum, $ticketsPerPage);
                [int[]] $TicketID = $queriedTickets.id   }  
        
            if ($TicketID -ne $null)
            {
                Write-Debug "Retrieving ConnectWise Tickets by Ticket ID"
                foreach ($ticket in $TicketID)
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

function New-CWServiceTicket 
{
    [CmdLetBinding()]
    param
    (
        [Parameter(ParameterSetName='ByProperties', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$BoardID,
        [Parameter(ParameterSetName='ByProperties', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$CompanyID,
        [Parameter(ParameterSetName='ByProperties', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [uint32]$ContactID,
        [Parameter(ParameterSetName='ByProperties', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Subject,
        [Parameter(ParameterSetName='ByProperties', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$Description,
        [Parameter(ParameterSetName='ByProperties', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$Internal,
        [Parameter(ParameterSetName='ByProperties', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [uint32]$PriorityID,
        [Parameter(ParameterSetName='ByProperties', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [uint32]$StatusID,
        [Parameter(ParameterSetName='ByProperties', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$BaseApiUrl,
        [Parameter(ParameterSetName='ByProperties', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$CompanyName,
        [Parameter(ParameterSetName='ByProperties', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PublicKey,
        [Parameter(ParameterSetName='ByProperties', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PrivateKey
    )
    
    Begin
    {
        # get the ticket service
        $TicketSvc = [CwApiServiceTicketSvc]::new($BaseApiUrl, $CompanyName, $PublicKey, $PrivateKey);
    }
    Process
    {
        $newTicket = $TicketSvc.CreateTicket($BoardID, $CompanyID, $ContactID, $Subject, $Description, $Internal, $StatusID, $PriorityID);
        return $newTicket;
    }
    End
    {
        # do nothing here
    }
} 

Export-ModuleMember -Function 'Get-CWServiceTicket';
Export-ModuleMember -Function 'New-CWServiceTicket';
