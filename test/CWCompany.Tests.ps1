# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "PSConnectWise" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\PSConnectWise\PSConnectWise.psm1" -Force 

Describe 'CWCompany' {
		
	. "$WorkspaceRoot\test\LoadTestSettings.ps1"
	
	# get the server connnection
	$pstrServer = Get-CWConnectionInfo -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
	
	Context 'Get-CWCompany' {
        
        $pstrCompanyIDs        = $pstrComp.companyIds;
		$pstrCompanyID         = $pstrComp.companyIds[0];
		$pstrCompanyIdentifier = $pstrComp.companyIdentifier;
	
        It 'gets company and checks for the id field' {
			$companyID = $pstrCompanyID;
			$company = Get-CWCompany -ID $companyID -Server $pstrServer
			$company.id | Should Be $companyID;		
		} 
		
		It 'gets company and pipes it through the Select-Object cmdlet for the id property' {
			$companyID = $pstrCompanyID;
			$company = Get-CWCompany -ID $companyID -Server $pstrServer;
			$company | Select-Object -ExpandProperty id | Should Be $companyID;		
		}
		
		It 'gets the id and subject properties of a company by using the -Property param' {
			$companyID = $pstrCompanyID;
			$fields = @("id", "identifier", "name");
			$company = Get-CWCompany -ID $companyID -Property $fields -Server $pstrServer;
			$company.PSObject.Properties | Measure-Object | Select -ExpandProperty Count | Should Be $fields.Count;		
		}
		
		It 'gets companies by passing array of company ids to the -ID param' {
			$companyIDs = $pstrCompanyIDs;
			$companies = Get-CWCompany -ID $companyIDs -Server $pstrServer;
			$companies | Measure-Object | Select -ExpandProperty Count | Should Be $companyIDs.Count;		
		}
		
		It 'gets list of companies that were piped to the cmdlet' {
			$companyIDs = $pstrCompanyIDs;
			$companies = $companyIDs | Get-CWCompany -Server $pstrServer;
			$companies | Measure-Object | Select -ExpandProperty Count | Should Be $companyIDs.Count;		
		}
		
		It 'gets company based on the -Filter param' {
			$filter = "id = $pstrCompanyID";
			$company = Get-CWCompany -Filter $filter -Server $pstrServer;
			$company.id | Should Be $pstrCompanyID;		
		}
		
		It 'gets company based on the -Filter param and uses the SizeLimit param' {
			$filter = "id IN ($([String]::Join(',', $pstrCompanyIDs)))";
			$sizeLimit =  2;
			$companies = Get-CWCompany -Filter $filter -SizeLimit $sizeLimit -Server $pstrServer;
			$companies | Measure-Object | Select -ExpandProperty Count | Should Be $sizeLimit;
		}
		
		It 'gets companies and sorts company id by descending piping cmdlet through Sort-Object cmdlet' {
			$companyIDs = $pstrCompanyIDs;
			$companies = Get-CWCompany -ID $companyIDs -Server $pstrServer | Sort -Descending id;
			$maxCompanyId = $companyIDs | Measure-Object -Maximum | Select -ExpandProperty Maximum;
			$companies[0].id | Should Be $maxCompanyId;		
		}
		
		It 'wildcard search using Identifier parameter with SizeLimit parameter' {
			$sizeLimit = 5;
			$companies = Get-CWCompany -Identifier "*" -SizeLimit $sizeLimit -Server $pstrServer;
			$companies | Measure-Object | Select -ExpandProperty Count | Should Be $sizeLimit ;
		}
		
		It 'get single company by Identifier parameter' {
			$companies = Get-CWCompany -Identifier $pstrCompanyIdentifier -Server $pstrServer;
			$companies.identifier | Should Be $pstrCompanyIdentifier;
		}
        
    }

}