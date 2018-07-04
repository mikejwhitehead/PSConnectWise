<#
.SYNOPSIS
    Gets ConnectWise (global) location information. 
.PARAMETER ID
    ConnectWise location ID
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
    Get-CWSystemLocation -ID 1 -Server $CWServer;
.EXAMPLE
    $CWServer = Set-CWSession -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWSystemLocation -Filter "name like '*normal*'" -Server $CWServer;
#>
function Get-CWSystemLocation
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
            $LocationSvc = [CwApiSystemLocationSvc]::new($Session);
        } 
        else 
        {
            Write-Error "No open ConnectWise session. See Set-CWSession for more information.";
        }
        
        [uint32] $locationCount = $MAX_ITEMS_PER_PAGE;
        [uint32] $pageCount  = 1;
        
        # get the number of pages of ticket to request and total ticket count
        if (![String]::IsNullOrWhiteSpace($Filter))
        {
            $locationCount = $LocationSvc.GetLocationCount($Filter);
            Write-Debug "Total Count Location the Filter ($Filter): $locationCount";
            
            if ($SizeLimit -ne $null -and $SizeLimit -gt 0)
            {
                Write-Verbose "Total Location Count Excess SizeLimit; Setting Location Count to the SizeLimit: $SizeLimit"
                $locationCount = [Math]::Min($locationCount, $SizeLimit);
            }
            $pageCount = [Math]::Ceiling([double]($locationCount / $MAX_ITEMS_PER_PAGE));
            
            Write-Debug "Total Number of Pages ($MAX_ITEMS_PER_PAGE Locations Per Pages): $pageCount";
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
                
                if ($null -ne $locationCount -and $locationCount -gt 0)
                {
                    # find how many Companies to retrieve
                    $itemsRemainCount = $locationCount - (($pageNum - 1) * $MAX_ITEMS_PER_PAGE);
                    $itemsPerPage = [Math]::Min($itemsRemainCount, $MAX_ITEMS_PER_PAGE);
                }    
                
                Write-Debug "Requesting Location IDs that Meets this Filter: $Filter";
                $queriedLocations = $LocationSvc.ReadLocations($Filter, $OrderBy, $pageNum, $itemsPerPage);
                [pscustomobject[]] $Locations = $queriedLocations;
                
                foreach ($Location in $Locations)
                {
                    Write-Verbose "Requesting ConnectWise Location Number: $Location";
                    if ($null -eq $Properties -or $Properties.Length -eq 0)
                    {
                        $Location;
                    }
                    else 
                    {
                        $Location;
                    }
                }
                
            } else {
                
                Write-Debug "Retrieving ConnectWise Locations by Location ID"
                foreach ($Location in $ID)
                {
                    Write-Verbose "Requesting ConnectWise Location Number: $Location";
                    if ($null -eq $Properties -or $Properties.Length -eq 0)
                    {
                        $LocationSvc.ReadLocation($Location);
                    }
                    else 
                    {
                        $LocationSvc.ReadLocation($Location, $Properties);
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

Export-ModuleMember -Function 'Get-CWSystemLocation';