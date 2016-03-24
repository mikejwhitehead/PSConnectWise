# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "CWServiceBoardStatusCmdLets" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\src\CWServiceBoardStatusCmdLets.psm1" -Force 

# dot-sources the definition file to get static variables (prefixed with 'pstr') to be used for testing
. "$WorkspaceRoot\pester\.test.variables.ps1" 

Describe 'Get-CWServiceBoardStatus' {
	
	It 'gets board status and check that the results is an array' {
		$boardID = $pstrBoardID;
		$statuses = Get-CWServiceBoardStatus -BoardID $boardID -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
		$statuses.GetType().BaseType.Name | Should Be "Array";		
	}
	
	It 'gets board and pipes it through the Select-Object cmdlet for the id property of the first object' {
		$boardID = $pstrBoardID;
		$status = Get-CWServiceBoardStatus -BoardID $boardID -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey | Select-Object boardId -First 1;
		$status | Select-Object -ExpandProperty boardId | Should Be $boardID;		
	}

} 