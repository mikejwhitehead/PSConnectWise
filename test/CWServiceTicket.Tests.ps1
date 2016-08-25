# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "PSConnectWise" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\PSConnectWise\PSConnectWise.psm1" -Force 

Describe 'CWServiceTicket' {
	
	. $($WorkspaceRoot + '\test\LoadTestSettings.ps1');
	[hashtable] $pstrSharedValues = @{};
	
	# get the server connnection
	Get-CWConnectionInfo -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
 
	Context 'Get-CWServiceTicket' {
		
		$pstrTicketID  = $pstrGenSvc.ticketIds[0];
		$pstrTicketIDs = $pstrGenSvc.ticketIds;
		
		It 'gets ticket and checks for the id field' {
			$ticketID = $pstrTicketID;
			$ticket = Get-CWServiceTicket -ID $ticketID;
			$pstrSharedValues.Add("ticket", $ticket);
			$pstrSharedValues['ticket'].id | Should Be $ticketID;		
			$ticket = Get-CWServiceTicket -ID $ticketID;
			$ticket.id | Should Be $ticketID;		
		} 
		
		It 'gets ticket and pipes it through the Select-Object cmdlet for the id property' {
			$ticketID = $pstrTicketID;
			$ticket = Get-CWServiceTicket -ID $ticketID;
			$ticket | Select-Object -ExpandProperty id | Should Be $ticketID;		
		}
		
		It 'gets the id and subject properties of a ticket by using the -Property param' {
			$ticketID = $pstrTicketID;
			$fields = @("id", "summary");
			$ticket = Get-CWServiceTicket -ID $ticketID -Property $fields;
			$ticket.PSObject.Properties | Measure-Object | Select-Object -ExpandProperty Count | Should Be $fields.Count;		
		}
		
		It 'gets tickets by passing array of ticket ids to the -ID param' {
			$ticketIDs = $pstrTicketIDs;
			$tickets = Get-CWServiceTicket -ID $ticketIDs;
			$tickets | Measure-Object | Select-Object -ExpandProperty Count | Should Be $ticketIDs.Count;		
		}
		
		It 'gets list of tickets that were piped to the cmdlet' {
			$ticketIDs = $pstrTicketIDs;
			$tickets = $ticketIDs | Get-CWServiceTicket;
			$tickets | Measure-Object | Select-Object -ExpandProperty Count | Should Be $ticketIDs.Count;		
		}
		
		It 'gets ticket based on the -Filter param' {
			$filter = "id = $pstrTicketID";
			$ticket = Get-CWServiceTicket -Filter $filter;
			$ticket.id | Should Be $pstrTicketID;		
		}
		
		It 'gets ticket based on the -Filter param and uses the SizeLimit param' {
			$filter = "id IN ($([String]::Join(',', $pstrTicketIDs)))";
			$sizeLimit =  2;
			$tickets = Get-CWServiceTicket -Filter $filter -SizeLimit $sizeLimit;
			$tickets | Measure-Object | Select-Object -ExpandProperty Count | Should Be $sizeLimit;
		}
		
		It 'gets tickets and sorts ticket id by descending piping cmdlet through Sort-Object cmdlet' {
			$ticketIDs = $pstrTicketIDs;
			$tickets = Get-CWServiceTicket -ID $ticketIDs | Sort-Object -Descending id;
			$maxTicketId = $ticketIDs | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
			$tickets[0].id | Should Be $maxTicketId;		
		}
		
		It 'wildcard search using Summary parameter with SizeLimit parameter' {
			$sizeLimit = 5;
			$ticketSummary = ($pstrSharedValues['ticket'].summary);
			$tickets = Get-CWServiceTicket -Summary "$ticketSummary*" -SizeLimit $sizeLimit;
			$count = $tickets | Measure-Object | Select-Object -ExpandProperty Count;
			$count -gt 0 -and $count -le $sizeLimit | Should Be $true;
		}
		
		It 'get tickets by Summary parameter' {
			$ticketSummary = $pstrSharedValues['ticket'].summary
			$tickets = Get-CWServiceTicket -Summary $ticketSummary;
			$tickets -ne $null | Should Be $true;
		}
		
		It 'wildcard search using Filter parameter with Descending parameter' {
			$sizeLimit = 5;
			$minTicketId = [Math]::Max(0, $pstrSharedValues['ticket'].id - 100);
			$tickets = Get-CWServiceTicket -Filter "id > $minTicketId" -SizeLimit $sizeLimit -Descending;
			$tickets[0].id -ge $tickets[$tickets.Count - 1].id | Should Be $true ;
		}
		
		
	} # end of Context 'Get-CWServiceTicket'
	
	Context "New-CWServiceTicket"  {
		
		$pstrTicketCompany  = $pstrProcNewTicket.ticketCompany
		$pstrTicketBoard    = $pstrProcNewTicket.ticketBoard
		#$pstrTicketContact  = $pstrProcNewTicket.ticketContact
		$pstrTicketStatus   = $pstrProcNewTicket.ticketStatus
		$pstrTicketPriority = $pstrProcNewTicket.ticketPriority
		$pstrTicketTitle    = $pstrProcNewTicket.ticketTitle
		$pstrTicketBody     = $pstrProcNewTicket.ticketBody
	
		It "create a new service ticket and check for the ticket number" {
			$ticket = New-CWServiceTicket -BoardID $pstrTicketBoard -CompanyID $pstrTicketCompany -ContactID $pstrNewTicketContact `
						-Status $pstrTicketStatus -PriorityID $pstrTicketPriority `
						-Subject $pstrTicketTitle -Description $pstrTicketBody
			$pstrSharedValues.Add("newTicketId", $ticket.id);
			$pstrSharedValues["newTicketId"] -gt 0 | Should Be $true; 
		} 
		
	} # end of Context "New-CWServiceTicket" 
	
	Context "Update-CWServiceTicket"  {
		
		$pstrTicketID  = $pstrGenSvc.ticketIds[0];
		$pstrStatusID  = $pstrGenSvc.statusIds[0];
		$pstrBoardID   = $pstrGenSvc.boardIds[0];
	
		It "change the status of a ticket" {
			$ticketID = $pstrTicketID;
			$statusID = $pstrStatusID;
			$ticket = Update-CWServiceTicket -ID $ticketID -StatusID $statusID;
			$ticket.status.id -eq $statusID | Should Be $true; 
		}
		
		It "change the status of a ticket and set the board ID" {
			$ticketID = $pstrTicketID;
			$statusID = $pstrStatusID;
			$boardID  = $pstrBoardID;
			
			$ticket = Update-CWServiceTicket -ID $ticketID -StatusID $statusID -BoardID $boardID;
			$ticket.status.id -eq $statusID -and $ticket.board.id -eq $boardID | Should Be $true; 
		}
		
		It "add a ticket note to a ticket" {
			$ticketID = $pstrTicketID;
			$ticket = Update-CWServiceTicket -ID $ticketID `
			            -Message "Testing new ticket note via update ticket command." -AddToDescription;
			$ticket.id -eq $ticketID | Should Be $true; 
		}
		
	} # end of Context "Update-CWServiceTicket" 
	
	Context "Remove-CWServiceTicket"  {
		
		It "deletes a ticket and check for a return value of true if successful" {
			$wasDeleted = Remove-CWServiceTicket -ID $pstrSharedValues["newTicketId"];
			$wasDeleted | Should Be $true; 
		}
	
	}
	
		
} # end of Describe 'CWServiceTicket'