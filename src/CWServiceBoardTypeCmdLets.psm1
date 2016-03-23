#dot-source import the classes
. "$PSScriptRoot\PSCWApiClasses.ps1"

function Get-CWServiceBoardType
{
    [CmdLetBinding()]
    param
    (
        [Parameter(ParameterSetName='SingleBoard', Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$BoardID,
        [Parameter(ParameterSetName='SingleBoard', Position=2, Mandatory=$true)]
        [Parameter(ParameterSetName='BoardQuery', Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$BaseApiUrl,
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
        $BoardTypeSvc = [CwApiServiceBoardTypeSvc]::new($BaseApiUrl, $CompanyName, $PublicKey, $PrivateKey);
        
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
                # find how many Status to retrieve
                $typesPerPage = $typeCount - (($pageNum - 1) * $MAX_ITEMS_PER_PAGE);
                
                Write-Debug "Requesting Type IDs for BoardID: $BoardID";
                $queriedTypes = $BoardTypeSvc.ReadTypes($boardId, [string[]] @("*"), $pageNum, $typesPerPage);
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