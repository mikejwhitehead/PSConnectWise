# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "PSConnectWise" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\PSConnectWise\PSConnectWise.psm1" -Force 

Describe -Tag 'ReqPriorityPermission' 'CWServicePriority' {
	
	. $($WorkspaceRoot + '\test\LoadTestSettings.ps1');
	
	# get the server connnection
	Set-CWSession -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
	
	Context 'Get-CWServicePriority' {
		
		$pstrPriorityID  = $pstrGenSvc.priorityIds[0];
		$pstrPriorityIDs = $pstrGenSvc.priorityIds;
	
		It 'gets priority and checks for the id field' {
			$priorityID = $pstrPriorityID;
			$priority = Get-CWServicePriority -ID $priorityID;
			$priority.id | Should Be $priorityID;		
		}
		
		It 'gets priority and pipes it through the Select-Object cmdlet for the id property' {
			$priorityID = $pstrPriorityID;
			$priority = Get-CWServicePriority -ID $priorityID;
			$priority | Select-Object -ExpandProperty id | Should Be $priorityID;		
		}
		
		It 'gets priorities by passing array of priority ids to the -ID param' {
			$priorityIDs = $pstrPriorityIDs;
			$priorities = Get-CWServicePriority -ID $priorityIDs;
			$priorities | Measure-Object | Select-Object -ExpandProperty Count | Should Be $priorityIDs.Count;		
		}
		
		It 'gets list of priorities that were piped to the cmdlet' {
			$priorityIDs = $pstrPriorityIDs;
			$priorities = $priorityIDs | Get-CWServicePriority;
			$priorities | Measure-Object | Select-Object -ExpandProperty Count | Should Be $priorityIDs.Count;		
		}
		
		It 'gets priority based on the -Filter param' {
			$filter = "id = $pstrPriorityID";
			$priority = Get-CWServicePriority -Filter $filter;
			$priority.id | Should Be $pstrPriorityID;		
		}
		
		It 'gets priority based on the -Filter param and uses the SizeLimit param' {
			$filter = "id IN ($([String]::Join(",", $pstrPriorityIDs)))";
			$sizeLimit =  2;
			$priorities = Get-CWServicePriority -Filter $filter -SizeLimit $sizeLimit;
			$priorities | Measure-Object | Select-Object -ExpandProperty Count | Should Be $sizeLimit;
		}
		
		It 'gets priorities and sorts priority id by descending piping cmdlet through Sort-Object cmdlet' {
			$priorityIDs = $pstrPriorityIDs;
			$priorities = Get-CWServicePriority -ID $priorityIDs | Sort-Object -Descending id;
			$maxpriorityID = $priorityIDs | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
			$priorities[0].id | Should Be $maxpriorityID;		
		}
	
	}

} 