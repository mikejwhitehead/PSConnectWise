<#
.SYNOPSIS
    Gets ConnectWise (global) source information. 
.PARAMETER ID
    ConnectWise source ID
.PARAMETER Filter
    Query String 
.PARAMETER SizeLimit
    Max number of items to return
.PARAMETER Descending
    Changes the sorting to descending order by IDs
.PARAMETER Server
    Variable to the object created via Get-CWConnectWiseInfo
.EXAMPLE
    $CWServer = Set-CWSession -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWServiceSource -ID 1 -Server $CWServer;
.EXAMPLE
    $CWServer = Set-CWSession -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWServiceSource -Filter "name like '*normal*'" -Server $CWServer;
#>
function Get-CWServiceSource
{
    [CmdLetBinding()]
    [OutputType("PSObject", ParameterSetName="Normal")]
    [OutputType("PSObject[]", ParameterSetName="Query")]
    [CmdletBinding(DefaultParameterSetName="Normal")]
    param
    (
        [Parameter(ParameterSetName='Normal', Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [int[]]$ID,
        [Parameter(ParameterSetName='Query', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,
        [Parameter(ParameterSetName='Query', Mandatory=$false)]
        [ValidateRange(1, 1000)]
        [uint32]$SizeLimit = 100,
        [Parameter(ParameterSetName='Query')]
        [switch]$Descending,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [Parameter(ParameterSetName='Query', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [PSObject]$Session = $script:CWSession
    )
    
    Begin
    {
        $MAX_ITEMS_PER_PAGE = 50;
        [string]$OrderBy = [String]::Empty;
        
        # get the service
        $BoardTypeSvc = $null;
        if ($Session -ne $null)
        {
            $SourceSvc = [CwApiServiceSourceSvc]::new($Session);
        } 
        else 
        {
            Write-Error "No open ConnectWise session. See Set-CWSession for more information.";
        }
        
        [uint32] $sourceCount = $MAX_ITEMS_PER_PAGE;
        [uint32] $pageCount  = 1;
        
        # get the number of pages of ticket to request and total ticket count
        if (![String]::IsNullOrWhiteSpace($Filter))
        {
            $sourceCount = $SourceSvc.GetSourceCount($Filter);
            Write-Debug "Total Count Source the Filter ($Filter): $sourceCount";
            
            if ($SizeLimit -ne $null -and $SizeLimit -gt 0)
            {
                Write-Verbose "Total Source Count Excess SizeLimit; Setting Source Count to the SizeLimit: $SizeLimit"
                $sourceCount = [Math]::Min($sourceCount, $SizeLimit);
            }
            $pageCount = [Math]::Ceiling([double]($sourceCount / $MAX_ITEMS_PER_PAGE));
            
            Write-Debug "Total Number of Pages ($MAX_ITEMS_PER_PAGE Sources Per Pages): $pageCount";
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
            if (![String]::IsNullOrWhiteSpace($Filter))
            {
                
                if ($null -ne $sourceCount -and $sourceCount -gt 0)
                {
                    # find how many Companies to retrieve
                    $itemsRemainCount = $sourceCount - (($pageNum - 1) * $MAX_ITEMS_PER_PAGE);
                    $itemsPerPage = [Math]::Min($itemsRemainCount, $MAX_ITEMS_PER_PAGE);
                }    
                
                Write-Debug "Requesting Source IDs that Meets this Filter: $Filter";
                $queriedSources = $SourceSvc.ReadSources($Filter, $OrderBy, $pageNum, $itemsPerPage);
                [pscustomobject[]] $Sources = $queriedSources;
                
                foreach ($Source in $Sources)
                {
                    Write-Verbose "Requesting ConnectWise Source Number: $Source";
                    if ($null -eq $Properties -or $Properties.Length -eq 0)
                    {
                        $Source;
                    }
                    else 
                    {
                        $Source;
                    }
                }
                
            } else {
                
                Write-Debug "Retrieving ConnectWise Sources by Source ID"
                foreach ($Source in $ID)
                {
                    Write-Verbose "Requesting ConnectWise Source Number: $Source";
                    if ($null -eq $Properties -or $Properties.Length -eq 0)
                    {
                        $SourceSvc.ReadSource($Source);
                    }
                    else 
                    {
                        $SourceSvc.ReadSource($Source, $Properties);
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

Export-ModuleMember -Function 'Get-CWServiceSource';