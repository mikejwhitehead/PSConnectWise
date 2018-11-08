<#
.SYNOPSIS
    Gets ConnectWise contact information. 
.PARAMETER ID
    ConnectWise contact ID
.PARAMETER CompanyID
    ConnectWise company ID
.PARAMETER Descending
    Changes the sorting to descending order by IDs
.PARAMETER Server
    Variable to the object created via Get-CWConnectWiseInfo
.EXAMPLE
    $CWServer = Set-CWSession -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWCompanyContact -ID 1 -Server $CWServer;
.EXAMPLE
    $CWServer = Set-CWSession -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWCompanyContact -CompanyID 1 -Server $CWServer;
#>
function Get-CWCompanyContact
{
    [CmdLetBinding()]
    [OutputType("PSObject[]", ParameterSetName="Normal")]
    [OutputType("PSObject", ParameterSetName="Single")]
    [CmdletBinding(DefaultParameterSetName="Normal")]
    param
    (
        [Parameter(ParameterSetName='Single', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$ID,
        [Parameter(ParameterSetName='Normal', Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$CompanyID,
        [Parameter(ParameterSetName='Normal')]
        [ValidateNotNullOrEmpty()]
        [string]$FirstName,
        [Parameter(ParameterSetName='Normal')]
        [ValidateNotNullOrEmpty()]
        [string]$LastName,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [ValidateRange(1, 1000)]
        [uint32]$SizeLimit = 100,
        [Parameter(ParameterSetName='Normal')]
        [switch]$Descending,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [Parameter(ParameterSetName='Single', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [PSObject]$Session = $script:CWSession
    )
    
    Begin
    {
        $MAX_ITEMS_PER_PAGE = 1000;
        [string]$OrderBy = [String]::Empty;

        # get the service
        $ContactSvc = $null;
        if ($Session -ne $null)
        {
            $ContactSvc = [CwApiCompanyContactSvc]::new($Session);
        } 
        else 
        {
            Write-Error "No open ConnectWise session. See Set-CWSession for more information.";
        }
        
        [uint32] $contactCount = $MAX_ITEMS_PER_PAGE;
        [uint32] $pageCount  = 1;
        
        # get the number of pages of company to request and total company count
        if ($ID -eq 0 -or $ID -eq $null)
        {
            [uint32]$contactCount = 0;
            
            if (![String]::IsNullOrWhiteSpace($FirstName) -or ![String]::IsNullOrWhiteSpace($LastName))
            {
                $Filter = "company/id=$CompanyID";
                
                if ([RegEx]::IsMatch($FirstName, "\*"))
                {
                    $Filter += " and firstname like '$FirstName'"
                }
                elseif (![String]::IsNullOrWhiteSpace($FirstName))
                {
                    $Filter += " and firstname='$FirstName'"
                }
                    
                if ([RegEx]::IsMatch($LastName, "\*"))
                {
                    $Filter += " and lastname like '$LastName'"
                }
                elseif (![String]::IsNullOrWhiteSpace($LastName))
                {
                    $Filter += " and lastname='$LastName'"
                }
                
                Write-Debug "Created a Filter String Based on the CompanyID, FirstName, and LastName: $Filter";
                $contactCount = $ContactSvc.GetContactCount($Filter);
            }
            else 
            {
                $contactCount = $ContactSvc.GetContactCount($CompanyID);
            }

            Write-Debug "Total Count of Company Contact Entries for Company ($CompanyID): $contactCount";
            
            if ($SizeLimit -ne $null -and $SizeLimit -gt 0)
            {
                Write-Verbose "Total Company Contacts Count Excess SizeLimit; Setting Company Contact Count to the SizeLimit: $SizeLimit"
                $contactCount = [Math]::Min($contactCount, $SizeLimit);
            }
            $pageCount = [Math]::Ceiling([double]($contactCount / $MAX_ITEMS_PER_PAGE));
            
            Write-Debug "Total Number of Pages ($MAX_ITEMS_PER_PAGE Company Contacts Per Pages): $pageCount";
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
            if ($ID -eq 0)
            {

                if ($null -ne $contactCount -and $contactCount -gt 0)
                {
                    # find how many Companies to retrieve
                    $itemsRemainCount = $contactCount - (($pageNum - 1) * $MAX_ITEMS_PER_PAGE);
                    $itemsPerPage = [Math]::Min($itemsRemainCount, $MAX_ITEMS_PER_PAGE);
                }
                
                [psobject[]] $Contacts = @();
                
                if ([String]::IsNullOrWhiteSpace($Filter))
                {
                    Write-Debug "Requesting Contact Entries for Company: $CompanyID";
                    $queriedContacts = $ContactSvc.ReadCompanyContacts($CompanyID, $null, $OrderBy, $pageNum, $itemsPerPage);
                    [psobject[]] $Contacts = $queriedContacts;
                }
                else 
                {
                    Write-Debug "Requesting Contact Entries for Company: $CompanyID";
                    $queriedContacts = $ContactSvc.ReadContacts($Filter, $null, $OrderBy, $pageNum, $itemsPerPage);
                    [psobject[]] $Contacts = $queriedContacts;
                }
                
            } else {
                
                $Contacts = $ContactSvc.ReadContact($ID);
            } 
            
            foreach ($Contact in $Contacts)
            {
                Write-Verbose "Requesting ConnectWise Company Contact Number: $($Contact.id)";
                $Contact;
            } 
                
        }
        
    }
    End
    {
        # do nothing here
    }
}

function New-CWCompanyContact
{
    [CmdLetBinding()]
    [OutputType("PSObject", ParameterSetName="Single")]
    [CmdletBinding(DefaultParameterSetName="Single")]
    param
    (
        [Parameter(ParameterSetName='Single', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$FirstName,
        [Parameter(ParameterSetName='Single', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$LastName,
        [Parameter(ParameterSetName='Single', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [bool]$InactiveFlag,
        [Parameter(ParameterSetName='Single', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Title,
        [Parameter(ParameterSetName='Single', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$EmailAddress,
        [Parameter(ParameterSetName='Single', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$PhoneNumber,
        [Parameter(ParameterSetName='Single', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$CompanyId,
        [Parameter(ParameterSetName='Single', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$SiteId,
        [Parameter(ParameterSetName='Single', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [PSObject]$Session = $script:CWSession
    )
    
    Begin
    {

        # get the service
        $ContactSvc = $null;
        if ($Session -ne $null)
        {
            $ContactSvc = [CwApiCompanyContactSvc]::new($Session);
        } 
        else 
        {
            Write-Error "No open ConnectWise session. See Set-CWSession for more information.";
        }
                
        
        
    }
    Process
    {
        if ($PhoneNumber){
            $newContact = $ContactSvc.CreateContact($FirstName,$LastName,$CompanyId,$SiteId,$InactiveFlag,$Title,$EmailAddress,$PhoneNumber)
        }
        else{
            $newContact = $ContactSvc.CreateContact($FirstName,$LastName,$CompanyId,$SiteId,$InactiveFlag,$Title,$EmailAddress,"")
        }
        $newContact         
    }
    End
    {
        # do nothing here
    }
}


Export-ModuleMember -Function 'Get-CWCompanyContact';
Export-ModuleMember -Function 'New-CWCompanyContact';