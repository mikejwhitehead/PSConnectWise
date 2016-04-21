<#
.SYNOPSIS
    Gets ConnectWise board information. 
.PARAMETER ID
    ConnectWise board ID
.PARAMETER Filter
    Query String 
.PARAMETER SizeLimit
    Max number of items to return
.PARAMETER Server
    Variable to the object created via Get-CWConnectWiseInfo
.EXAMPLE
    $CWServer = Get-CWConnectionInfo -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWServiceBoard -ID 1 -Server $CWServer;
.EXAMPLE
    $CWServer = Get-CWConnectionInfo -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWServiceBoard -Query "ID in (1, 2, 3, 4, 5)" -Server $CWServer;
#>
function Get-CWServiceBoard
{
    [CmdLetBinding()]
    [OutputType("PSObject[]", ParameterSetName="Normal")]
    [OutputType("PSObject", ParameterSetName="Single")]
    param
    (
        [Parameter(ParameterSetName='Normal', Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [int[]]$ID,
        [Parameter(ParameterSetName='Query', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,
        [Parameter(ParameterSetName='Query', Mandatory=$false)]
        [int]$SizeLimit,
        [Parameter(ParameterSetName='Normal', Position=2, Mandatory=$true)]
        [Parameter(ParameterSetName='Query', Position=2, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSObject]$Server
    )
    
    Begin
    {
        $MAX_ITEMS_PER_PAGE = 50;
        [CwApiServiceBoardSvc] $BoardSvc = $null; 
        
        # get the Company service
        if ($Server -ne $null)
        {
            $BoardSvc = [CwApiServiceBoardSvc]::new($Server);
        } 
        else 
        {
            # TODO: determine whether or not to keep this as an option
            $BoardSvc = [CwApiServiceBoardSvc]::new($Domain, $CompanyName, $PublicKey, $PrivateKey);
        }
        
        [uint32] $boardCount = $MAX_ITEMS_PER_PAGE;
        [uint32] $pageCount  = 1;
        
        # get the number of pages of ticket to request and total ticket count
        if (![String]::IsNullOrWhiteSpace($Filter))
        {
            $boardCount = $BoardSvc.GetBoardCount($Filter);
            Write-Debug "Total Count Board the Filter ($Filter): $boardCount";
            
            if ($SizeLimit -ne $null -and $SizeLimit -gt 0)
            {
                Write-Verbose "Total Board Count Excess SizeLimit; Setting Board Count to the SizeLimit: $SizeLimit"
                $boardCount = [Math]::Min($boardCount, $SizeLimit);
            }
            $pageCount = [Math]::Ceiling([double]($boardCount / $MAX_ITEMS_PER_PAGE));
            
            Write-Debug "Total Number of Pages ($MAX_ITEMS_PER_PAGE Boards Per Pages): $pageCount";
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
                
                if ($boardCount -ne $null -and $boardCount -gt 0)
                {
                    # find how many Companies to retrieve
                    $itemsLeftToRetrived = $boardCount - (($pageNum - 1) * $MAX_ITEMS_PER_PAGE);
                    $itemsPerPage = [Math]::Min($itemsLeftToRetrived, $MAX_ITEMS_PER_PAGE);
                }
                
                Write-Debug "Requesting Board IDs that Meets this Filter: $Filter";
                $queriedBoards = $BoardSvc.ReadBoards($Filter, $pageNum, $itemsPerPage);
                [pscustomobject[]] $Boards = $queriedBoards;
                
                foreach ($Board in $Boards)
                {
                    Write-Verbose "Requesting ConnectWise Board Number: $Board";
                    if ($Properties -eq $null -or $Properties.Length -eq 0)
                    {
                        $Board;
                    }
                    else 
                    {
                        $Board;
                    }
                }
                
            } else {
                
                Write-Debug "Retrieving ConnectWise Boards by Board ID"
                foreach ($Board in $ID)
                {
                    Write-Verbose "Requesting ConnectWise Board Number: $Board";
                    if ($Properties -eq $null -or $Properties.Length -eq 0)
                    {
                        $BoardSvc.ReadBoard($Board);
                    }
                    else 
                    {
                        $BoardSvc.ReadBoard($Board, $Properties);
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

Export-ModuleMember -Function 'Get-CWServiceBoard';