#dot-source import the classes
. "$PSScriptRoot\PSCWApiClasses.ps1"

function Get-CWCompanyContact
{
    [CmdLetBinding()]
    param
    (
        [Parameter(ParameterSetName='CompanyContacts', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$CompanyID,
        [Parameter(ParameterSetName='SingleContact', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [uint32]$ID,
        [Parameter(ParameterSetName='CompanyContacts', Position=1, Mandatory=$true)]
        [Parameter(ParameterSetName='SingleContact', Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$BaseApiUrl,
        [Parameter(ParameterSetName='CompanyContacts', Position=1, Mandatory=$true)]
        [Parameter(ParameterSetName='SingleContact', Position=2, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$CompanyName,
        [Parameter(ParameterSetName='CompanyContacts', Position=1, Mandatory=$true)]
        [Parameter(ParameterSetName='SingleContact', Position=3, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PublicKey,
        [Parameter(ParameterSetName='CompanyContacts', Position=1, Mandatory=$true)]
        [Parameter(ParameterSetName='SingleContact', Position=4, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PrivateKey
    )
    
    Begin
    {
        $MAX_ITEMS_PER_PAGE = 50;
        
        # get the TimeEntry service
        $ContactSvc = [CwApiCompanyContactSvc]::new($BaseApiUrl, $CompanyName, $PublicKey, $PrivateKey);
        
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
                # find how many contacts a company has to retrieve
                $itemsPerPage = $contactCount - (($pageNum - 1) * $MAX_ITEMS_PER_PAGE);
                
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