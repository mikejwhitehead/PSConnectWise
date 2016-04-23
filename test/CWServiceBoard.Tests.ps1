# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "PSConnectWise" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\PSConnectWise\PSConnectWise.psm1" -Force 

Describe 'CWServiceBoard' {
		
	. "$WorkspaceRoot\test\LoadTestSettings.ps1"
	
	# get the server connnection
	$pstrServer = Get-CWConnectionInfo -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
	
	Context 'Get-CWServiceBoard' {
		
		$pstrBoardIDs  = $pstrGenSvc.boardIds;
		$pstrBoardID   = $pstrGenSvc.boardIds[0];
		$pstrBoardName = $pstrGenSvc.boardName;
	
		It 'gets board and checks for the id field' {
			$boardID = $pstrBoardID;
			$board = Get-CWServiceBoard -ID $boardID -Server $pstrServer;
			$board.id | Should Be $boardID;		
		}
		
		It 'gets board and pipes it through the Select-Object cmdlet for the id property' {
			$boardID = $pstrBoardID;
			$board = Get-CWServiceBoard -ID $boardID -Server $pstrServer;
			$board | Select-Object -ExpandProperty id | Should Be $boardID;		
		}
		
		It 'gets boards by passing array of board ids to the -ID param' {
			$boardIDs = $pstrBoardIDs;
			$boards = Get-CWServiceBoard -ID $boardIDs -Server $pstrServer;
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
			$boards = Get-CWServiceBoard -ID $boardIDs -Server $pstrServer | Sort -Descending id;
			$maxBoardId = $boardIDs | Measure-Object -Maximum | Select -ExpandProperty Maximum
			$boards[0].id | Should Be $maxBoardId;		
		}
		
		It 'wildcard search using Name parameter with SizeLimit parameter' {
			$sizeLimit = 5;
			$boards = Get-CWServiceBoard -Name "*" -SizeLimit $sizeLimit -Server $pstrServer;
			$boards.GetType().BaseType.Name | Should Be "Array";
		}
		
		It 'get single board by Name parameter' {
			$boards = Get-CWServiceBoard -Name $pstrBoardName -Server $pstrServer;
			$boards.name | Should Be $pstrBoardName;
		}
	
	}

} 