# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "PSConnectWise" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\PSConnectWise\PSConnectWise.psm1" -Force 

Describe 'CWServiceBoardType' {

	. $($WorkspaceRoot + '\test\LoadTestSettings.ps1');
	
	# get the server connnection
	Get-CWConnectionInfo -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
	
	Context 'Get-CWServiceBoardType' {
		
		$pstrBoardID  = $pstrGenSvc.boardIds[0];
	
		It 'gets board status and check that the results is an array' {
			$boardID = $pstrBoardID;
			$types = Get-CWServiceBoardType -BoardID $boardID;
			$types.GetType().BaseType.Name | Should Be "Array";		
		}
		
		It 'gets board and pipes it through the Select-Object cmdlet for the id property of the first object' {
			$boardID = $pstrBoardID;
			$type = Get-CWServiceBoardType -BoardID $boardID | Select-Object boardId -First 1;
			$type | Select-Object -ExpandProperty boardId | Should Be $boardID;		
		}
	
	}

} 