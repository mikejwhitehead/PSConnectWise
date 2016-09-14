<#
.SYNOPSIS
    Gets ConnectWise member information. 
.PARAMETER ID
    ConnectWise member ID
.PARAMETER FirstName
    First name of the member
.PARAMETER LastName
    Last name of the member 
.PARAMETER Filter
    Query String 
.PARAMETER SizeLimit
    Max number of items to return
.PARAMETER Descending
    Changes the sorting to descending order by IDs
.PARAMETER Server
    Variable to the object created via Get-CWConnectWiseInfo
.NOTES
    ConnectWise API-Only Members do not have access to the CW System module. Therefore, this function will not work for API only members. 
.EXAMPLE
    $CWServer = Get-CWConnectionInfo -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWSystemMember -ID 1 -Server $CWServer;
.EXAMPLE
    $CWServer = Get-CWConnectionInfo -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWSystemMember -Email "John.Doe@example.com" -Server $CWServer;
.EXAMPLE
    $CWServer = Get-CWConnectionInfo -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWSystemMember -Query "ID in (1, 2, 3, 4, 5)" -Server $CWServer;
#>
function Get-CWSystemMember
{
    [CmdLetBinding()]
    [OutputType("PSObject", ParameterSetName="Normal")]
    [OutputType("PSObject[]", ParameterSetName="Name")]
    [OutputType("PSObject[]", ParameterSetName="Query")]
    [OutputType("PSObject", ParameterSetName="Username")]
    [CmdletBinding(DefaultParameterSetName="Normal")]
    param
    (
        [Parameter(ParameterSetName='Normal', Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [int[]]$ID,
        [Parameter(ParameterSetName='Username', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,
        [Parameter(ParameterSetName='Name', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$FirstName,
        [Parameter(ParameterSetName='Name', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$LastName,
        [Parameter(ParameterSetName='Query', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,
        [Parameter(ParameterSetName='Name')]
        [Parameter(ParameterSetName='Query')]
        [ValidateRange(1, 1000)]
        [uint32]$SizeLimit = 5,
        [Parameter(ParameterSetName='Name')]
        [Parameter(ParameterSetName='Query')]
        [switch]$Descending,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [Parameter(ParameterSetName='Query', Mandatory=$false)]
        [Parameter(ParameterSetName='Name', Mandatory=$false)]
        [Parameter(ParameterSetName='Email', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Property,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [Parameter(ParameterSetName='Query', Mandatory=$false)]
        [Parameter(ParameterSetName='Name', Mandatory=$false)]
        [Parameter(ParameterSetName='Email', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [PSObject]$Server = $script:CWServerInfo
    )
    
    Begin
    {
        $MAX_ITEMS_PER_PAGE = 50;
        [string]$OrderBy = [String]::Empty;
        
        # get the Member- service
        $MemberSvc = [CwApiSystemMemberSvc]::new($Server);
        
        [uint32] $memberCount = $MAX_ITEMS_PER_PAGE;
        [uint32] $pageCount  = 1;
        
        # get the number of pages of ticket to request and total ticket count
        if (![String]::IsNullOrWhiteSpace($Filter) -or ![String]::IsNullOrWhiteSpace($FirstName) -or ![String]::IsNullOrWhiteSpace($LastName))
        {
            if (![String]::IsNullOrWhiteSpace($FirstName))
            {
                $Filter = "firstName='$FirstName'";
                if ([RegEx]::IsMatch($FirstName, "\*"))
                {
                    $Filter = "firstName like '$FirstName'";

                }
                Write-Verbose "Created a Filter String Based on the Identifier Value ($FirstName): $Filter";
            }

            if (![String]::IsNullOrWhiteSpace($LastName))
            {
                $Filter = "lastName='$LastName'";
                if ([RegEx]::IsMatch($LastName, "\*"))
                {
                    $Filter = "lastName like '$LastName'";

                }
                Write-Verbose "Created a Filter String Based on the Identifier Value ($LastName): $Filter";
            }
            
            $memberCount = $MemberSvc.GetMemberCount($Filter);
            Write-Debug "Total Count Member the Filter ($Filter): $memberCount";
            
            if ($SizeLimit -ne $null -and $SizeLimit -gt 0)
            {
                Write-Verbose "Total Member Count Excess SizeLimit; Setting Member Count to the SizeLimit: $SizeLimit"
                $memberCount = [Math]::Min($memberCount, $SizeLimit);
            }
            $pageCount = [Math]::Ceiling([double]($memberCount / $MAX_ITEMS_PER_PAGE));
            
            Write-Debug "Total Number of Pages ($MAX_ITEMS_PER_PAGE Members Per Pages): $pageCount";
        }
        
        #specify the ordering
        if ($Descending)
        {
            $OrderBy = " id desc";
        }
        
        # determines if to select all fields or specific fields
        [string[]] $Properties = $null;
        if ($null -ne $Property)
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
                
                if ($null -ne $memberCount -and $memberCount -gt 0)
                {
                    # find how many Companies to retrieve
                    $itemsRemainCount = $memberCount - (($pageNum - 1) * $MAX_ITEMS_PER_PAGE);
                    $itemsPerPage = [Math]::Min($itemsRemainCount, $MAX_ITEMS_PER_PAGE);
                }
                
                Write-Debug "Requesting Member IDs that Meets this Filter: $Filter";
                $queriedMembers = $MemberSvc.ReadMembers($Filter, $OrderBy, $pageNum, $itemsPerPage);
                [pscustomobject[]] $Members = $queriedMembers;
                
                foreach ($Member in $Members)
                {
                    Write-Verbose "Requesting ConnectWise Member Number: $Member";
                    if ($null -eq $Properties -or $Properties.Length -eq 0)
                    {
                        $Member;
                    }
                    else 
                    {
                        $Member;
                    }
                }
                
            } else {
                
                if (![String]::IsNullOrEmpty($Username))
                {
                    Write-Debug "Retrieving ConnectWise Members by Member Username";
                    if ($null -eq $Properties -or $Properties.Length -eq 0)
                    {
                        $MemberSvc.ReadMember($Username);
                    }
                    else 
                    {
                        $MemberSvc.ReadMember($Username, $Properties);
                    }
                }
                else
                {
                    Write-Debug "Retrieving ConnectWise Members by Member ID"
                    foreach ($Member in $ID)
                    {
                        Write-Verbose "Requesting ConnectWise Member Number: $Member";
                        if ($null -eq $Properties -or $Properties.Length -eq 0)
                        {
                            $MemberSvc.ReadMember([uint32] $Member);
                        }
                        else 
                        {
                            $MemberSvc.ReadMember([uint32] $Member, $Properties);
                        }
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

Export-ModuleMember -Function 'Get-CWSystemMember';