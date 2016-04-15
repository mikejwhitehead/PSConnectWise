# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "CWServiceBoardTypeCmdLets" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\src\CWServiceBoardTypeCmdLets.psm1" -Force 

Describe 'CWServiceBoardType' {

	. "$WorkspaceRoot\test\LoadTestSettings.ps1"
	
	Context 'Get-CWServiceBoardType' {
		
		$pstrBoardID  = $pstrGenSvc.boardIds[0];
	
		It 'gets board status and check that the results is an array' {
			$boardID = $pstrBoardID;
			$types = Get-CWServiceBoardType -BoardID $boardID -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			$types.GetType().BaseType.Name | Should Be "Array";		
		}
		
		It 'gets board and pipes it through the Select-Object cmdlet for the id property of the first object' {
			$boardID = $pstrBoardID;
			$type = Get-CWServiceBoardType -BoardID $boardID -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate | Select-Object boardId -First 1;
			$type | Select-Object -ExpandProperty boardId | Should Be $boardID;		
		}
	
	}

} 