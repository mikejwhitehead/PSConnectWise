#dot-source import the classes
. "$PSScriptRoot\PSCWApiClasses.ps1"

function Get-CWServiceBoard
{
    [CmdLetBinding()]
    param
    (
        [Parameter(ParameterSetName='SingleBoard', Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [int[]]$BoardID,
        [Parameter(ParameterSetName='BoardQuery', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,
        [Parameter(ParameterSetName='BoardQuery', Mandatory=$false)]
        [int]$SizeLimit,
        [Parameter(ParameterSetName='SingleBoard', Position=2, Mandatory=$true)]
        [Parameter(ParameterSetName='BoardQuery', Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Domain,
        [Parameter(ParameterSetName='SingleBoard', Position=3, Mandatory=$true)]
        [Parameter(ParameterSetName='BoardQuery', Position=2, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$CompanyName,
        [Parameter(ParameterSetName='SingleBoard', Position=4, Mandatory=$true)]
        [Parameter(ParameterSetName='BoardQuery', Position=3, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PublicKey,
        [Parameter(ParameterSetName='SingleBoard', Position=5, Mandatory=$true)]
        [Parameter(ParameterSetName='BoardQuery', Position=4, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PrivateKey
    )
    
    Begin
    {
        $MAX_ITEMS_PER_PAGE = 50;
        
        # get the Board service
        $BoardSvc = [CwApiServiceBoardSvc]::new($Domain, $CompanyName, $PublicKey, $PrivateKey);
        
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
                # find how many boards to retrieve
                $itemsPerPage = $boardCount - (($pageNum - 1) * $MAX_ITEMS_PER_PAGE);
                
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
                foreach ($Board in $BoardID)
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