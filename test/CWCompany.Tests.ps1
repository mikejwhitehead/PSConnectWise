# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "PSConnectWise" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\PSConnectWise\PSConnectWise.psm1" -Force 

Describe 'CWCompany' {
		
	. "$WorkspaceRoot\test\LoadTestSettings.ps1"
	
	# get the server connnection
	Get-CWConnectionInfo -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
	
	Context 'Get-CWCompany' {
        
        $pstrCompanyIDs = $pstrComp.companyIds;
		$pstrCompanyID  = $pstrComp.companyIds[0];
    
	
        It 'gets company and checks for the id field' {
			$companyID = $pstrCompanyID;
			$company = Get-CWCompany -ID $companyID
			$company.id | Should Be $companyID;		
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
			$company.PSObject.Properties | Measure-Object | Select -ExpandProperty Count | Should Be $fields.Count;		
		}
		
		It 'gets tickets by passing array of company ids to the -ID param' {
			$companyIDs = $pstrCompanyIDs;
			$tickets = Get-CWCompany -ID $companyIDs;
			$tickets | Measure-Object | Select -ExpandProperty Count | Should Be $companyIDs.Count;		
		}
		
		It 'gets list of tickets that were piped to the cmdlet' {
			$companyIDs = $pstrCompanyIDs;
			$tickets = $companyIDs | Get-CWCompany
			$tickets | Measure-Object | Select -ExpandProperty Count | Should Be $companyIDs.Count;		
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
			$tickets | Measure-Object | Select -ExpandProperty Count | Should Be $sizeLimit;
		}
		
		It 'gets tickets and sorts company id by descending piping cmdlet through Sort-Object cmdlet' {
			$companyIDs = $pstrCompanyIDs;
			$tickets = Get-CWCompany -ID $companyIDs | Sort -Descending id;
			$maxTicketId = $companyIDs | Measure-Object -Maximum | Select -ExpandProperty Maximum
			$tickets[0].id | Should Be $maxTicketId;		
		}
        
    }

}