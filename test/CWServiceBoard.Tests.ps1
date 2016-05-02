# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "PSConnectWise" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\PSConnectWise\PSConnectWise.psm1" -Force 

Describe 'CWServiceBoard' {
		
	. "$WorkspaceRoot\test\LoadTestSettings.ps1"
	[hashtable] $pstrSharedValues = @{};

	# get the server connnection
	Get-CWConnectionInfo -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
	
	Context 'Get-CWServiceBoard' {
		
		$pstrBoardIDs  = $pstrGenSvc.boardIds;
		$pstrBoardID   = $pstrGenSvc.boardIds[0];
		$pstrBoardName = $pstrGenSvc.boardName;
	
		It 'gets board and checks for the id field' {
			$boardID = $pstrBoardID;
			$board = Get-CWServiceBoard -ID $boardID;
			$pstrSharedValues.Add("board", $board);
			$pstrSharedValues['board'].id | Should Be $boardID;		
		}
		
		It 'gets board and pipes it through the Select-Object cmdlet for the id property' {
			$boardID = $pstrBoardID;
			$board = Get-CWServiceBoard -ID $boardID;
			$board | Select-Object -ExpandProperty id | Should Be $boardID;		
		}
		
		It 'gets boards by passing array of board ids to the -ID param' {
			$boardIDs = $pstrBoardIDs;
			$boards = Get-CWServiceBoard -ID $boardIDs;
			$boards | Measure-Object | Select -ExpandProperty Count | Should Be $boardIDs.Count;		
		}
		
		It 'gets list of boards that were piped to the cmdlet' {
			$boardIDs = $pstrBoardIDs;
			$boards = $boardIDs | Get-CWServiceBoard;
			$boards | Measure-Object | Select -ExpandProperty Count | Should Be $boardIDs.Count;		
		}
		
		It 'gets board based on the -Filter param' {
			$filter = "id = $pstrBoardID";
			$board = Get-CWServiceBoard -Filter $filter;
			$board.id | Should Be $pstrBoardID;		
		}
		
		It 'gets board based on the -Filter param and uses the SizeLimit param' {
			$filter = "id IN ($([String]::Join(",", $pstrBoardIDs)))";
			$sizeLimit =  2;
			$boards = Get-CWServiceBoard -Filter $filter -SizeLimit $sizeLimit;
			$boards | Measure-Object | Select -ExpandProperty Count | Should Be $sizeLimit;
		}
		
		It 'gets boards and sorts board id by descending piping cmdlet through Sort-Object cmdlet' {
			$boardIDs = $pstrBoardIDs;
			$boards = Get-CWServiceBoard -ID $boardIDs | Sort -Descending id;
			$maxBoardId = $boardIDs | Measure-Object -Maximum | Select -ExpandProperty Maximum
			$boards[0].id | Should Be $maxBoardId;		
		}
		
		It 'wildcard search using Name parameter with SizeLimit parameter' {
			$sizeLimit = 5;
			$boards = Get-CWServiceBoard -Name "*" -SizeLimit $sizeLimit;
			$boards.GetType().BaseType.Name | Should Be "Array";
		}
		
		It 'get single board by Name parameter' {
			$boardName = $pstrSharedValues['board'].name
			$boards = Get-CWServiceBoard -Name $boardName;
			$boards.name | Should Be $boardName;
		}
	
	}

} 