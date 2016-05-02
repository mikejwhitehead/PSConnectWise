# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "PSConnectWise" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\PSConnectWise\PSConnectWise.psm1" -Force 

Describe 'CWCompanyContact' {
	
	. "$WorkspaceRoot\test\LoadTestSettings.ps1";
	[hashtable] $pstrSharedValues = @{};
	
	# get the server connnection
	Get-CWConnectionInfo -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
	
	Context 'Get-CWCompanyContact' {

		$pstrCompanyIDs  = $pstrComp.companyIds;
		$pstrCompanyID   = $pstrComp.companyIds[0];
		$pstrContactIDs  = $pstrComp.contactIds;
		$pstrContactID   = $pstrComp.contactIds[0];
	
		It 'gets a single contact' {
			$contactID = $pstrContactID;
			$contact = Get-CWCompanyContact -ID $contactID;
			$pstrSharedValues.Add("contact", $contact);
			$pstrSharedValues['contact'] | Select-Object -ExpandProperty id | Should Be $contactID;		
		}
		
		It 'gets company contact entries for a company and check that the results is an array' {
			$companyID = $pstrCompanyID;
			$contacts = Get-CWCompanyContact -CompanyID $companyID;
			$contacts.GetType().BaseType.Name | Should Be "Array";		
		}
		
		It 'gets a single contact from a company and pipes it through the Select-Object cmdlet for the id property of the first object' {
			$companyID = $pstrCompanyID;
			$contact = Get-CWCompanyContact -CompanyID $companyID | Select-Object -First 1;
			$contact.company.id | Should Be $companyID;		
		}
		
		It 'search for contact by first name' {
			$sizeLimit = 5;
			$firstName = $pstrSharedValues['contact'].firstname;
			$companyID = $pstrSharedValues['contact'].company.id;
			$contacts = Get-CWCompanyContact -CompanyID $companyID -FirstName $firstName -SizeLimit $sizeLimit;
			$contact = $contacts | Select -First 1; 
			$contact.id -gt 0 |  Should Be $true;		
		}

		It 'gets a single contact' {
			$contactID = $pstrContactID;
			$contact = Get-CWCompanyContact -ID $contactID;
			$contact | Select-Object -ExpandProperty id | Should Be $contactID;		
		}
		
		It 'search for contact by last name' {
			$sizeLimit = 5;
			$lastName = $pstrSharedValues['contact'].lastname;
			$companyID = $pstrSharedValues['contact'].company.id;
			$contacts = Get-CWCompanyContact -CompanyID $companyID -LastName $lastName -SizeLimit $sizeLimit;
			$contact = $contacts | Select -First 1; 
			$contact.id -gt 0 |  Should Be $true;		
		}
		
		It 'wildcard search for contact by first name' {
			$sizeLimit = 5;
			$companyID = $pstrSharedValues['contact'].company.id;
			$contacts = Get-CWCompanyContact -CompanyID $companyID -FirstName "*" -SizeLimit $sizeLimit;
			$contact = $contacts | Select -First 1; 
			$contact.id -gt 0 |  Should Be $true;		
		}
		
		It 'wildcard search for contact by last name' {
			$sizeLimit = 5;
			$companyID = $pstrSharedValues['contact'].company.id;
			$contacts = Get-CWCompanyContact -CompanyID $companyID -LastName "*" -SizeLimit $sizeLimit;
			$contact = $contacts | Select -First 1; 
			$contact.id -gt 0 |  Should Be $true;		
		}
		
		It 'wildcard search with the Descending parameter' {
			$sizeLimit = 5;
			$companyID = $pstrSharedValues['contact'].company.id;
			$contacts = Get-CWCompanyContact -CompanyID $companyID -LastName "*" -SizeLimit $sizeLimit -Descending;
			$contacts[0].id -gt $contacts[$contacts.Count - 1].id | Should Be $true ;	
		}			
	}
	
} 