#dot-source import the classes
. "$PSScriptRoot\PSCWApiClasses.ps1"

function Get-CWServicePriority
{
    [CmdLetBinding()]
    param
    (
        [Parameter(ParameterSetName='SinglePriority', Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [int[]]$PriorityID,
        [Parameter(ParameterSetName='PriorityQuery', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,
        [Parameter(ParameterSetName='PriorityQuery', Mandatory=$false)]
        [int]$SizeLimit,
        [Parameter(ParameterSetName='SinglePriority', Position=2, Mandatory=$true)]
        [Parameter(ParameterSetName='PriorityQuery', Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$BaseApiUrl,
        [Parameter(ParameterSetName='SinglePriority', Position=3, Mandatory=$true)]
        [Parameter(ParameterSetName='PriorityQuery', Position=2, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$CompanyName,
        [Parameter(ParameterSetName='SinglePriority', Position=4, Mandatory=$true)]
        [Parameter(ParameterSetName='PriorityQuery', Position=3, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PublicKey,
        [Parameter(ParameterSetName='SinglePriority', Position=5, Mandatory=$true)]
        [Parameter(ParameterSetName='PriorityQuery', Position=4, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PrivateKey
    )
    
    Begin
    {
        $MAX_ITEMS_PER_PAGE = 50;
        
        # get the Priority service
        $PrioritySvc = [CwApiServicePrioritySvc]::new($BaseApiUrl, $CompanyName, $PublicKey, $PrivateKey);
        
        [uint32] $priorityCount = $MAX_ITEMS_PER_PAGE;
        [uint32] $pageCount  = 1;
        
        # get the number of pages of ticket to request and total ticket count
        if (![String]::IsNullOrWhiteSpace($Filter))
        {
            $priorityCount = $PrioritySvc.GetPriorityCount($Filter);
            Write-Debug "Total Count Priority the Filter ($Filter): $priorityCount";
            
            if ($SizeLimit -ne $null -and $SizeLimit -gt 0)
            {
                Write-Verbose "Total Priority Count Excess SizeLimit; Setting Priority Count to the SizeLimit: $SizeLimit"
                $priorityCount = [Math]::Min($priorityCount, $SizeLimit);
            }
            $pageCount = [Math]::Ceiling([double]($priorityCount / $MAX_ITEMS_PER_PAGE));
            
            Write-Debug "Total Number of Pages ($MAX_ITEMS_PER_PAGE Priorities Per Pages): $pageCount";
        }
        
    }
    Process
    {
        
        for ($pageNum = 1; $pageNum -le $pageCount; $pageNum++)
        {
            if (![String]::IsNullOrWhiteSpace($Filter))
            {
                # find how many priorities to retrieve
                $itemsPerPage = $priorityCount - (($pageNum - 1) * $MAX_ITEMS_PER_PAGE);
                
                Write-Debug "Requesting Priority IDs that Meets this Filter: $Filter";
                $queriedPriorities = $PrioritySvc.ReadPriorities($Filter, $pageNum, $itemsPerPage);
                [pscustomobject[]] $Priorities = $queriedPriorities;
                
                foreach ($Priority in $Priorities)
                {
                    Write-Verbose "Requesting ConnectWise Priority Number: $Priority";
                    if ($Properties -eq $null -or $Properties.Length -eq 0)
                    {
                        $Priority;
                    }
                    else 
                    {
                        $Priority;
                    }
                }
                
            } else {
                
                Write-Debug "Retrieving ConnectWise Priorities by Priority ID"
                foreach ($Priority in $PriorityID)
                {
                    Write-Verbose "Requesting ConnectWise Priority Number: $Priority";
                    if ($Properties -eq $null -or $Properties.Length -eq 0)
                    {
                        $PrioritySvc.ReadPriority($Priority);
                    }
                    else 
                    {
                        $PrioritySvc.ReadPriority($Priority, $Properties);
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

Export-ModuleMember -Function 'Get-CWServicePriority';