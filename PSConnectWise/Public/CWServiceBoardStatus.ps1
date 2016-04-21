<#
.SYNOPSIS
    Gets ConnectWise board's status information. 
.PARAMETER BoardID
    ConnectWise board ID
.PARAMETER Server
    Variable to the object created via Get-CWConnectWiseInfo
.EXAMPLE
    $CWServer = Get-CWConnectionInfo -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWServiceBoardStatus -BoardID 1 -Server $CWServer;
#>
function Get-CWServiceBoardStatus
{
    [CmdLetBinding()]
    [OutputType("PSObject[]", ParameterSetName="Normal")]
    param
    (
        [Parameter(ParameterSetName='Normal', Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$BoardID,
        [Parameter(ParameterSetName='Normal', Position=2, Mandatory=$true)]
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
                
                if ($statusCount -ne $null -and $statusCount -gt 0)
                {
                    # find how many Companies to retrieve
                    $itemsLeftToRetrived = $statusCount - (($pageNum - 1) * $MAX_ITEMS_PER_PAGE);
                    $itemsPerPage = [Math]::Min($itemsLeftToRetrived, $MAX_ITEMS_PER_PAGE);
                }
                
                Write-Debug "Requesting Ticket IDs that Meets this Filter: $Filter";
                $queriedStatuses = $BoardStatusSvc.ReadStatuses($boardId, [string[]] @("*"), $pageNum, $itemsPerPage);
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