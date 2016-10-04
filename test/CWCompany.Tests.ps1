# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "PSConnectWise" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\PSConnectWise\PSConnectWise.psm1" -Force 

Describe 'CWCompany' {
		
	. $($WorkspaceRoot + '\test\LoadTestSettings.ps1');
	[hashtable] $pstrSharedValues = @{};
	
	# get the server connnection
	Set-CWSession -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
	
	Context 'Get-CWCompany' {
        
        $pstrCompanyIDs        = $pstrComp.companyIds;
		$pstrCompanyID         = $pstrComp.companyIds[0];
		$pstrCompanyIdentifier = $pstrComp.companyIdentifier;
		$pstrCompanyName       = $pstrComp.companyName;
	
        It 'gets company and checks for the id field' {
			$companyID = $pstrCompanyID;
			$company = Get-CWCompany -ID $companyID;
			$pstrSharedValues.Add("company", $company);
			$pstrSharedValues['company'].id | Should Be $companyID;		
		} 
		
		It 'gets company and pipes it through the Select-Object cmdlet for the id property' {
			$companyID = $pstrCompanyID;
			$company = Get-CWCompany -ID $companyID;
			$company | Select-Object -ExpandProperty id | Should Be $companyID;		
		}
		
		It 'gets the id and subject properties of a company by using the -Property param' {
			$companyID = $pstrCompanyID;
			$fields = @("id", "identifier", "name");
			$company = Get-CWCompany -ID $companyID -Property $fields;
			$company.PSObject.Properties | Measure-Object | Select-Object -ExpandProperty Count | Should Be $fields.Count;		
		}
		
		It 'gets companies by passing array of company ids to the -ID param' {
			$companyIDs = $pstrCompanyIDs;
			$tickets = Get-CWCompany -ID $companyIDs;
			$tickets | Measure-Object | Select-Object -ExpandProperty Count | Should Be $companyIDs.Count;		
		}
		
		It 'gets list of companies that were piped to the cmdlet' {
			$companyIDs = $pstrCompanyIDs;
			$tickets = $companyIDs | Get-CWCompany
			$tickets | Measure-Object | Select-Object -ExpandProperty Count | Should Be $companyIDs.Count;		
		}
		
		It 'gets company based on the -Filter param' {
			$filter = "id = $pstrCompanyID";
			$company = Get-CWCompany -Filter $filter;
			$company.id | Should Be $pstrCompanyID;		
		}
		
		It 'gets company based on the -Filter param and uses the SizeLimit param' {
			$filter = "id IN ($([String]::Join(',', $pstrCompanyIDs)))";
			$sizeLimit =  2;
			$tickets = Get-CWCompany -Filter $filter -SizeLimit $sizeLimit;
			$tickets | Measure-Object | Select-Object -ExpandProperty Count | Should Be $sizeLimit;
		}
		
		It 'gets companies and sorts company id by descending piping cmdlet through Sort-Object cmdlet' {
			$companyIDs = $pstrCompanyIDs;
			$companies = Get-CWCompany -ID $companyIDs | Sort-Object -Descending id;
			$maxCompanyId = $companyIDs | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum;
			$companies[0].id | Should Be $maxCompanyId;		
		}
		
		It 'wildcard search using Identifier parameter with SizeLimit parameter' {
			$sizeLimit = 5;
			$companies = Get-CWCompany -Identifier "*" -SizeLimit $sizeLimit;
			$companies | Measure-Object | Select-Object -ExpandProperty Count | Should Be $sizeLimit ;
		}
		
		It 'get single company by Identifier parameter' {
			$companyIdentifier = $pstrSharedValues['company'].identifier
			$companies = Get-CWCompany -Identifier $companyIdentifier;
			$companies.identifier | Should Be $companyIdentifier;
		}
		
		It 'wildcard search using Name parameter with SizeLimit parameter' {
			$sizeLimit = 5;
			$companies = Get-CWCompany -Name "*" -SizeLimit $sizeLimit;
			$companies | Measure-Object | Select-Object -ExpandProperty Count | Should Be $sizeLimit ;
		}
		
		It 'get single company by Name parameter' {
			$companyName = $pstrSharedValues['company'].name
			$companies = Get-CWCompany -Name $companyName;
			$companyName -ne $null | Should Be $true;
		}
		
		It 'wildcard search using Name parameter with Descending parameter' {
			$sizeLimit = 5;
			$companies = Get-CWCompany -Name "*" -SizeLimit $sizeLimit -Descending;
			$companies[0].id -gt $companies[$companies.Count - 1].id | Should Be $true;
		}
        
    }

}