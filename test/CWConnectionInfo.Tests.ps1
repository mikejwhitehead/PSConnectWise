# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "PSConnectWise" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\PSConnectWise\PSConnectWise.psm1" -Force 

Describe 'CWConnectionInfo' {

	. $($WorkspaceRoot + '\test\LoadTestSettings.ps1');
	
	Context 'Set-CWSession' {
	
		It 'gets server connection information and checks it for the domain' {
			$session = Set-CWSession -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			$session.Domain | Should Be $pstrSvrDomain
		}
		
	}

} 