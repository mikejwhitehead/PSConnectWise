#dot-source import the classes
. "$PSScriptRoot\PSCWApiClasses.ps1"

function Get-CWServiceBoardStatus
{
    [CmdLetBinding()]
    [OutputType("PSObject[]", ParameterSetName="Normal")]
    [OutputType("PSObject", ParameterSetName="Single")]
    param
    (
        [Parameter(ParameterSetName='Normal', Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$BoardID,
        [Parameter(ParameterSetName='Normal', Position=2, Mandatory=$true)]
        [Parameter(ParameterSetName='Query', Position=2, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSObject]$Server
    )
    
    Begin
    {
        $MAX_ITEMS_PER_PAGE = 50;
        [CwApiServiceBoardStatusSvc] $BoardStatusSvc = $null; 
        
        # get the Company service
        if ($Server -ne $null)
        {
            $BoardStatusSvc = [CwApiServiceBoardStatusSvc]::new($Server);
        } 
        else 
        {
            # TODO: determine whether or not to keep this as an option
            $BoardStatusSvc = [CwApiServiceBoardStatusSvc]::new($Domain, $CompanyName, $PublicKey, $PrivateKey);
        }
        
        [uint32] $statusCount = $MAX_ITEMS_PER_PAGE;
        [uint32] $pageCount  = 1;
        
        # get the number of pages of board status to request and total ticket count
        if ($BoardID -gt 0)
        {
            $statusCount = $BoardStatusSvc.GetStatusCount([uint32]$BoardID);
            
            if ($SizeLimit -ne $null -and $SizeLimit -gt 0)
            {
                Write-Verbose "Total Board Count Excess SizeLimit; Setting Board Count to the SizeLimit: $SizeLimit"
                $statusCount = [Math]::Min($statusCount, $SizeLimit);
            }
            $pageCount = [Math]::Ceiling([double]($statusCount / $MAX_ITEMS_PER_PAGE));
            
            Write-Debug "Total Number of Pages ($MAX_ITEMS_PER_PAGE Boards Per Pages): $pageCount";
        }
    }
    Process
    {
        for ($pageNum = 1; $pageNum -le $pageCount; $pageNum++)
        {
            if ($BoardID -gt 0)
            {
                # find how many Status to retrieve
                $statusesPerPage = $statusCount - (($pageNum - 1) * $MAX_ITEMS_PER_PAGE);
                
                Write-Debug "Requesting Ticket IDs that Meets this Filter: $Filter";
                $queriedStatuses = $BoardStatusSvc.ReadStatuses($boardId, [string[]] @("*"), $pageNum, $statusesPerPage);
                [pscustomobject[]] $Statuses = $queriedStatuses;
                
                foreach ($Status in $Statuses)
                {
                    $Status
                }
                
            }  elseif ($StatusID -ne $null) {
                
                Write-Debug "Retrieving ConnectWise Status by Ticket ID"
                foreach ($status in $StatusID)
                {
                    Write-Verbose "Requesting ConnectWise Ticket Number: $status";
                    $BoardStatusSvc.ReadStatus($boardId, $status);
                }
                
            }
        }
    }
    End
    {
        # do nothing here
    }
}

Export-ModuleMember -Function 'Get-CWServiceBoardStatus';