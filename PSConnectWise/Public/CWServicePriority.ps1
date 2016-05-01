<#
.SYNOPSIS
    Gets ConnectWise (global) priority information. 
.PARAMETER ID
    ConnectWise priority ID
.PARAMETER Filter
    Query String 
.PARAMETER SizeLimit
    Max number of items to return
.PARAMETER Server
    Variable to the object created via Get-CWConnectWiseInfo
.EXAMPLE
    $CWServer = Get-CWConnectionInfo -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWServicePriority -ID 1 -Server $CWServer;
.EXAMPLE
    $CWServer = Get-CWConnectionInfo -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWServicePriority -Filter "name like '*normal*'" -Server $CWServer;
#>
function Get-CWServicePriority
{
    [CmdLetBinding()]
    [OutputType("PSObject[]", ParameterSetName="Normal")]
    [OutputType("PSObject[]", ParameterSetName="Query")]
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
        [Parameter(ParameterSetName='Normal', Position=1, Mandatory=$false)]
        [Parameter(ParameterSetName='Query', Position=1, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [PSObject]$Server = $script:CWServerInfo
    )
    
    Begin
    {
        $MAX_ITEMS_PER_PAGE = 50;
        [CwApiServicePrioritySvc] $PrioritySvc = $null; 
        
        # get the Company service
        $PrioritySvc = [CwApiServicePrioritySvc]::new($Server)
        
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
                foreach ($Priority in $ID)
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