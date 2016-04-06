# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "CWServiceBoardCmdLets" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\src\CWServiceBoardCmdLets.psm1" -Force 

# dot-sources the definition file to get static variables (prefixed with 'pstr') to be used for testing
. "$WorkspaceRoot\pester\.test.variables.ps1" 

Describe 'CWServiceBoard' {
	
	Context 'Get-CWServiceBoard' {
	
		It 'gets board and checks for the id field' {
			$boardID = $pstrBoardID;
			$board = Get-CWServiceBoard -BoardID $boardID -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
			$board.id | Should Be $boardID;		
		}
		
		It 'gets board and pipes it through the Select-Object cmdlet for the id property' {
			$boardID = $pstrBoardID;
			$board = Get-CWServiceBoard -BoardID $boardID -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
			$board | Select-Object -ExpandProperty id | Should Be $boardID;		
		}
		
		It 'gets boards by passing array of board ids to the -BoardID param' {
			$boardIDs = $pstrBoardIDs;
			$boards = Get-CWServiceBoard -BoardID $boardIDs -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
			$boards | Measure-Object | Select -ExpandProperty Count | Should Be $boardIDs.Count;		
		}
		
		It 'gets list of boards that were piped to the cmdlet' {
			$boardIDs = $pstrBoardIDs;
			$boards = $boardIDs | Get-CWServiceBoard -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
			$boards | Measure-Object | Select -ExpandProperty Count | Should Be $boardIDs.Count;		
		}
		
		It 'gets board based on the -Filter param' {
			$filter = "id = $pstrBoardID";
			$board = Get-CWServiceBoard -Filter $filter -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
			$board.id | Should Be $pstrBoardID;		
		}
		
		It 'gets board based on the -Filter param and uses the SizeLimit param' {
			$filter = "id IN ($([String]::Join(",", $pstrBoardIDs)))";
			$sizeLimit =  2;
			$boards = Get-CWServiceBoard -Filter $filter -SizeLimit $sizeLimit -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
			$boards | Measure-Object | Select -ExpandProperty Count | Should Be $sizeLimit;
		}
		
		It 'gets boards and sorts board id by descending piping cmdlet through Sort-Object cmdlet' {
			$boardIDs = $pstrBoardIDs;
			$boards = Get-CWServiceBoard -BoardID $boardIDs -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey | Sort -Descending id;
			$maxBoardId = $boardIDs | Measure-Object -Maximum | Select -ExpandProperty Maximum
			$boards[0].id | Should Be $maxBoardId;		
		}
	
	}

} 