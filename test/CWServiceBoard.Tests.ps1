# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "CWServiceBoardCmdLets" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\src\CWServiceBoardCmdLets.psm1" -Force 

Describe 'CWServiceBoard' {
		
	. "$WorkspaceRoot\test\LoadTestSettings.ps1"
	
	# get the server connnection
	$pstrServer = Get-CWConnectionInfo -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
	
	Context 'Get-CWServiceBoard' {
		
		$pstrBoardIDs = $pstrGenSvc.boardIds;
		$pstrBoardID  = $pstrGenSvc.boardIds[0];
	
		It 'gets board and checks for the id field' {
			$boardID = $pstrBoardID;
			$board = Get-CWServiceBoard -BoardID $boardID -Server $pstrServer;
			$board.id | Should Be $boardID;		
		}
		
		It 'gets board and pipes it through the Select-Object cmdlet for the id property' {
			$boardID = $pstrBoardID;
			$board = Get-CWServiceBoard -BoardID $boardID -Server $pstrServer;
			$board | Select-Object -ExpandProperty id | Should Be $boardID;		
		}
		
		It 'gets boards by passing array of board ids to the -BoardID param' {
			$boardIDs = $pstrBoardIDs;
			$boards = Get-CWServiceBoard -BoardID $boardIDs -Server $pstrServer;
			$boards | Measure-Object | Select -ExpandProperty Count | Should Be $boardIDs.Count;		
		}
		
		It 'gets list of boards that were piped to the cmdlet' {
			$boardIDs = $pstrBoardIDs;
			$boards = $boardIDs | Get-CWServiceBoard -Server $pstrServer;
			$boards | Measure-Object | Select -ExpandProperty Count | Should Be $boardIDs.Count;		
		}
		
		It 'gets board based on the -Filter param' {
			$filter = "id = $pstrBoardID";
			$board = Get-CWServiceBoard -Filter $filter -Server $pstrServer;
			$board.id | Should Be $pstrBoardID;		
		}
		
		It 'gets board based on the -Filter param and uses the SizeLimit param' {
			$filter = "id IN ($([String]::Join(",", $pstrBoardIDs)))";
			$sizeLimit =  2;
			$boards = Get-CWServiceBoard -Filter $filter -SizeLimit $sizeLimit -Server $pstrServer;
			$boards | Measure-Object | Select -ExpandProperty Count | Should Be $sizeLimit;
		}
		
		It 'gets boards and sorts board id by descending piping cmdlet through Sort-Object cmdlet' {
			$boardIDs = $pstrBoardIDs;
			$boards = Get-CWServiceBoard -BoardID $boardIDs -Server $pstrServer | Sort -Descending id;
			$maxBoardId = $boardIDs | Measure-Object -Maximum | Select -ExpandProperty Maximum
			$boards[0].id | Should Be $maxBoardId;		
		}
	
	}

} 