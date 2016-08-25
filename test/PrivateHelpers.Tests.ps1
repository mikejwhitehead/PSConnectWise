# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "PSConnectWise" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\PSConnectWise\PSConnectWise.psm1" -Force 

Describe 'PrivateHelpers' {
	
	. $($WorkspaceRoot + '\test\LoadTestSettings.ps1');
	
	Context 'Split-TimeSpan' {
	
		It 'splits time and checks correct number of returned entries' {
			$started = Get-Date;
            $ended   = $started.AddDays(1);
			$entries = Split-TimeSpan -Start $started -End $ended;
			$entries.Count | Should Be 2;		
		}
	
	}

} 