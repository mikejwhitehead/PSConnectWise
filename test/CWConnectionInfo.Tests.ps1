# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "CWConnectionInfoCmdLets" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\src\CWConnectionInfoCmdLets.psm1" -Force 

Describe 'CWConnectionInfo' {

	. "$WorkspaceRoot\test\LoadTestSettings.ps1"
	
	Context 'Get-CWConnectionInfo' {
	
		It 'gets server connection information and checks it for the domain' {
			$server = Get-CWConnectionInfo -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			$server.Domain | Should Be $pstrSvrDomain		
		}
		
	}

} 