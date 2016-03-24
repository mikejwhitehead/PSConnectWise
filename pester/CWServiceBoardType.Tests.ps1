# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "CWServiceBoardTypeCmdLets" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\src\CWServiceBoardTypeCmdLets.psm1" -Force 

# dot-sources the definition file to get static variables (prefixed with 'pstr') to be used for testing
. "$WorkspaceRoot\pester\.test.variables.ps1" 

Describe 'Get-CWServiceBoardType' {
	
	It 'gets board status and check that the results is an array' {
		$boardID = $pstrBoardID;
		$types = Get-CWServiceBoardType -BoardID $boardID -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
		$types.GetType().BaseType.Name | Should Be "Array";		
	}
	
	It 'gets board and pipes it through the Select-Object cmdlet for the id property of the first object' {
		$boardID = $pstrBoardID;
		$type = Get-CWServiceBoardType -BoardID $boardID -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey | Select-Object boardId -First 1;
		$type | Select-Object -ExpandProperty boardId | Should Be $boardID;		
	}

} 