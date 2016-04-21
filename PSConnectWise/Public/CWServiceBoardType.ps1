<#
.SYNOPSIS
    Gets ConnectWise board's type and subtype information. 
.PARAMETER BoardID
    ConnectWise board ID
.PARAMETER Server
    Variable to the object created via Get-CWConnectWiseInfo
.EXAMPLE
    $CWServer = Get-CWConnectionInfo -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWServiceBoardType -BoardID 1 -Server $CWServer;
#>
function Get-CWServiceBoardType
{
    [CmdLetBinding()]
    [OutputType("PSObject[]", ParameterSetName="Normal")]
    param
    (
        [Parameter(ParameterSetName='Normal', Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$BoardID,
        [Parameter(ParameterSetName='Normal', Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSObject]$Server
    )
    
    Begin
    {
        $MAX_ITEMS_PER_PAGE = 50;
        [CwApiServiceBoardTypeSvc] $BoardTypeSvc = $null; 
        
        # get the Company service
        if ($Server -ne $null)
        {
            $BoardTypeSvc = [CwApiServiceBoardTypeSvc]::new($Server);
        } 
        else 
        {
            # TODO: determine whether or not to keep this as an option
            $BoardTypeSvc = [CwApiServiceBoardTypeSvc]::new($Domain, $CompanyName, $PublicKey, $PrivateKey);
        }
        
        [uint32] $typeCount = $MAX_ITEMS_PER_PAGE;
        [uint32] $pageCount  = 1;
        
        # get the number of pages of board status to request and total ticket count
        if ($BoardID -gt 0)
        {
            $typeCount = $BoardTypeSvc.GetTypeCount([uint32]$BoardID);
            
            if ($SizeLimit -ne $null -and $SizeLimit -gt 0)
            {
                Write-Verbose "Total Board Count Excess SizeLimit; Setting Board Count to the SizeLimit: $SizeLimit"
                $typeCount = [Math]::Min($typeCount, $SizeLimit);
            }
            $pageCount = [Math]::Ceiling([double]($typeCount / $MAX_ITEMS_PER_PAGE));
            
            Write-Debug "Total Number of Pages ($MAX_ITEMS_PER_PAGE Types Per Pages): $pageCount";
        }
    }
    Process
    {
        for ($pageNum = 1; $pageNum -le $pageCount; $pageNum++)
        {
            if ($BoardID -gt 0)
            {
                
                if ($typeCount -ne $null -and $typeCount -gt 0)
                {
                    # find how many Companies to retrieve
                    $itemsLeftToRetrived = $typeCount - (($pageNum - 1) * $MAX_ITEMS_PER_PAGE);
                    $itemsPerPage = [Math]::Min($itemsLeftToRetrived, $MAX_ITEMS_PER_PAGE);
                }                
                
                Write-Debug "Requesting Type IDs for BoardID: $BoardID";
                $queriedTypes = $BoardTypeSvc.ReadTypes($boardId, [string[]] @("*"), $pageNum, $itemsPerPage);
                [pscustomobject[]] $Types = $queriedTypes;
                
                foreach ($Type in $Types)
                {
                    $Type
                }
                
            } elseIf ($TypeID -ne $null) {
                
                Write-Debug "Retrieving Connec tWise Board Type by Ticket ID"
                foreach ($type in $TypeID)
                {
                    Write-Verbose "Requesting ConnectWise Board Type Number: $type";
                    $BoardTypeSvc.ReadType($boardId, $type);
                }
                
            }
        }
    }
    End
    {
        # do nothing here
    }
}

Export-ModuleMember -Function 'Get-CWServiceBoardType';