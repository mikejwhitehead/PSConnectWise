<#
.SYNOPSIS
    Gets ConnectWise board's item and subitem information. 
.PARAMETER BoardID
    ConnectWise board ID
.PARAMETER Descending
    Changes the sorting to descending order by IDs
.PARAMETER Server
    Variable to the object created via Get-CWConnectWiseInfo
.EXAMPLE
    $CWServer = Set-CWSession -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWServiceBoardItem -BoardID 1 -Server $CWServer;
#>
function Get-CWServiceBoardItem
{
    [CmdLetBinding()]
    [OutputType("PSObject[]", ParameterSetName="Normal")]
    [CmdletBinding(DefaultParameterSetName="Normal")]
    param
    (
        [Parameter(ParameterSetName='Normal', Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$BoardID,
        [Parameter(ParameterSetName='Normal')]
        [switch]$Descending,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [PSObject]$Session = $script:CWSession
    )
    
    Begin
    {
        $MAX_ITEMS_PER_PAGE = 50;
        [string]$OrderBy = [String]::Empty;
        
        # get the service
        $BoardItemSvc = $null;
        if ($Session -ne $null)
        {
            $BoardItemSvc = [CwApiServiceBoardItemSvc]::new($Session);
        } 
        else 
        {
            Write-Error "No open ConnectWise session. See Set-CWSession for more information.";
        }
        
        [uint32] $itemCount = $MAX_ITEMS_PER_PAGE;
        [uint32] $pageCount  = 1;
        
        # get the number of pages of board status to request and total ticket count
        if ($BoardID -gt 0)
        {
            $itemCount = $BoardItemSvc.GetItemCount([uint32]$BoardID);
            
            if ($null -ne $SizeLimit -and $SizeLimit -gt 0)
            {
                Write-Verbose "Total Board Count Excess SizeLimit; Setting Board Count to the SizeLimit: $SizeLimit"
                $itemCount = [Math]::Min($itemCount, $SizeLimit);
            }
            $pageCount = [Math]::Ceiling([double]($itemCount / $MAX_ITEMS_PER_PAGE));
            
            Write-Debug "Total Number of Pages ($MAX_ITEMS_PER_PAGE Items Per Pages): $pageCount";
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
            if ($BoardID -gt 0)
            {
                
                if ($null -ne $itemCount -and $itemCount -gt 0)
                {
                    # find how many Companies to retrieve
                    $itemsRemainCount = $itemCount - (($pageNum - 1) * $MAX_ITEMS_PER_PAGE);
                    $itemsPerPage = [Math]::Min($itemsRemainCount, $MAX_ITEMS_PER_PAGE);
                }                
                
                Write-Debug "Requesting Item IDs for BoardID: $BoardID";
                $queriedItems = $BoardItemSvc.ReadItems($boardId, [string[]] @("*"), $OrderBy, $pageNum, $itemsPerPage);
                [pscustomobject[]] $Items = $queriedItems;
                
                foreach ($Item in $Items)
                {
                    $Item
                }
                
            } elseIf ($null -ne $ItemID) {
                
                Write-Debug "Retrieving Connec tWise Board Item by Ticket ID"
                foreach ($item in $ItemID)
                {
                    Write-Verbose "Requesting ConnectWise Board Item Number: $item";
                    $BoardItemSvc.ReadItem($boardId, $item);
                }
                
            }
        }
    }
    End
    {
        # do nothing here
    }
}

Export-ModuleMember -Function 'Get-CWServiceBoardItem';