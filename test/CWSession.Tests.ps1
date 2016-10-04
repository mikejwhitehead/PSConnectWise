# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "PSConnectWise" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\PSConnectWise\PSConnectWise.psm1" -Force 

Describe 'CWSession' {

	. $($WorkspaceRoot + '\test\LoadTestSettings.ps1');
	
	Context 'Set-CWSession' {
	
		It 'gets server connection information and checks it for the domain' {
			$newSession = Set-CWSession -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			$newSession.Domain | Should Be $pstrSvrDomain
		}
		
	}

	Context 'Test-CWSession' {
	
		It 'tests for successful server connection without explicitly passing session data' {
			$cwSession = Set-CWSession -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			Test-CWSession | Should Be $true;
		}

		It 'tests for successful server connection' {
			$goodSession = Set-CWSession -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			Test-CWSession -Session $goodSession | Should Be $true;
		}


		It 'tests for fail server connection' {
			$badSession = Set-CWSession -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey "123456";
			Test-CWSession -Session $badSession | Should Be $false;
		}
		
	}

} 