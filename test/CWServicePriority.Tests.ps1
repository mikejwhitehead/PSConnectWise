# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "CWServicePriorityCmdLets" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\src\CWServicePriorityCmdLets.psm1" -Force 

Describe -Tag 'ReqPriorityPermission' 'CWServicePriority' {
	
	. "$WorkspaceRoot\test\LoadTestSettings.ps1"
	
	Context 'Get-CWServicePriority' {
		
		$pstrPriorityID  = $pstrGenSvc.priorityIds[0];
		$pstrPriorityIDs = $pstrGenSvc.priorityIds;
	
		It 'gets priority and checks for the id field' {
			$priorityID = $pstrPriorityID;
			$priority = Get-CWServicePriority -PriorityID $priorityID -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			$priority.id | Should Be $priorityID;		
		}
		
		It 'gets priority and pipes it through the Select-Object cmdlet for the id property' {
			$priorityID = $pstrPriorityID;
			$priority = Get-CWServicePriority -PriorityID $priorityID -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			$priority | Select-Object -ExpandProperty id | Should Be $priorityID;		
		}
		
		It 'gets priorities by passing array of priority ids to the -PriorityID param' {
			$priorityIDs = $pstrPriorityIDs;
			$priorities = Get-CWServicePriority -PriorityID $priorityIDs -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			$priorities | Measure-Object | Select -ExpandProperty Count | Should Be $priorityIDs.Count;		
		}
		
		It 'gets list of priorities that were piped to the cmdlet' {
			$priorityIDs = $pstrPriorityIDs;
			$priorities = $priorityIDs | Get-CWServicePriority -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			$priorities | Measure-Object | Select -ExpandProperty Count | Should Be $priorityIDs.Count;		
		}
		
		It 'gets priority based on the -Filter param' {
			$filter = "id = $pstrPriorityID";
			$priority = Get-CWServicePriority -Filter $filter -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			$priority.id | Should Be $pstrPriorityID;		
		}
		
		It 'gets priority based on the -Filter param and uses the SizeLimit param' {
			$filter = "id IN ($([String]::Join(",", $pstrPriorityIDs)))";
			$sizeLimit =  2;
			$priorities = Get-CWServicePriority -Filter $filter -SizeLimit $sizeLimit -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			$priorities | Measure-Object | Select -ExpandProperty Count | Should Be $sizeLimit;
		}
		
		It 'gets priorities and sorts priority id by descending piping cmdlet through Sort-Object cmdlet' {
			$priorityIDs = $pstrPriorityIDs;
			$priorities = Get-CWServicePriority -PriorityID $priorityIDs -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate | Sort -Descending id;
			$maxpriorityID = $priorityIDs | Measure-Object -Maximum | Select -ExpandProperty Maximum
			$priorities[0].id | Should Be $maxpriorityID;		
		}
	
	}

} 