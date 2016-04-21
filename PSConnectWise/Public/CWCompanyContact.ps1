<#
.SYNOPSIS
    Gets ConnectWise contact information. 
.PARAMETER ID
    ConnectWise contact ID
.PARAMETER CompanyID
    ConnectWise company ID
.PARAMETER Server
    Variable to the object created via Get-CWConnectWiseInfo
.EXAMPLE
    $CWServer = Get-CWConnectionInfo -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWCompanyContact -ID 1 -Server $CWServer;
.EXAMPLE
    $CWServer = Get-CWConnectionInfo -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
    Get-CWCompanyContact -CompanyID 1 -Server $CWServer;
#>
function Get-CWCompanyContact
{
    [CmdLetBinding()]
    [OutputType("PSObject[]", ParameterSetName="Normal")]
    [OutputType("PSObject", ParameterSetName="Single")]
    param
    (
        [Parameter(ParameterSetName='Normal', Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$CompanyID,
        [Parameter(ParameterSetName='Single', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$ID,
        [Parameter(ParameterSetName='Normal', Position=1, Mandatory=$true)]
        [Parameter(ParameterSetName='Single', Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSObject]$Server
    )
    
    Begin
    {
        $MAX_ITEMS_PER_PAGE = 50;
        
        [CwApiCompanyContactSvc] $ContactSvc = $null; 
        
        # get the Company service
        if ($Server -ne $null)
        {
            $ContactSvc = [CwApiCompanyContactSvc]::new($Server);
        } 
        else 
        {
            # TODO: determine whether or not to keep this as an option
            $ContactSvc = [CwApiCompanyContactSvc]::new($Domain, $CompanyName, $PublicKey, $PrivateKey);
        }
        
        [uint32] $contactCount = $MAX_ITEMS_PER_PAGE;
        [uint32] $pageCount  = 1;
        
        # get the number of pages of company to request and total company count
        if ($ID -eq 0 -or $ID -eq $null)
        {
            $contactCount = $ContactSvc.GetContactCount($CompanyID);
            Write-Debug "Total Count of Company Contact Entries for Company ($CompanyID): $contactCount";
            
            if ($SizeLimit -ne $null -and $SizeLimit -gt 0)
            {
                Write-Verbose "Total Company Contacts Count Excess SizeLimit; Setting Company Contact Count to the SizeLimit: $SizeLimit"
                $contactCount = [Math]::Min($contactCount, $SizeLimit);
            }
            $pageCount = [Math]::Ceiling([double]($contactCount / $MAX_ITEMS_PER_PAGE));
            
            Write-Debug "Total Number of Pages ($MAX_ITEMS_PER_PAGE Company Contacts Per Pages): $pageCount";
        }
    }
    Process
    {
        
        for ($pageNum = 1; $pageNum -le $pageCount; $pageNum++)
        {
            if ($ID -eq 0)
            {

                if ($contactCount -ne $null -and $contactCount -gt 0)
                {
                    # find how many Companies to retrieve
                    $itemsLeftToRetrived = $contactCount - (($pageNum - 1) * $MAX_ITEMS_PER_PAGE);
                    $itemsPerPage = [Math]::Min($itemsLeftToRetrived, $MAX_ITEMS_PER_PAGE);
                }
                
                Write-Debug "Requesting Contact Entries for Company: $CompanyID";
                $queriedContacts = $ContactSvc.ReadCompanyContacts($CompanyID, $null, $pageNum, $itemsPerPage);
                [pscustomobject[]] $Contacts = $queriedContacts;
            
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

Export-ModuleMember -Function 'Get-CWCompanyContact';