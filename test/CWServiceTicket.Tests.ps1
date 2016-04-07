# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "CWServiceTicketCmdLets" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\src\CWServiceTicketCmdLets.psm1" -Force 

Describe 'CWServiceTicket' {
	
	. "$WorkspaceRoot\test\LoadTestSettings.ps1"

	Context 'Get-CWServiceTicket' {
		
		$pstrTicketID  = $pstrGenSvc.ticketIds[0];
		$pstrTicketIDs = $pstrGenSvc.ticketIds;
		
		It 'gets ticket and checks for the id field' {
			$ticketID = $pstrTicketID;
			$ticket = Get-CWServiceTicket -TicketID $ticketID `
						-BaseApiUrl $pstrSvrUrl -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			$ticket.id | Should Be $ticketID;		
		} 
		
		It 'gets ticket and pipes it through the Select-Object cmdlet for the id property' {
			$ticketID = $pstrTicketID;
			$ticket = Get-CWServiceTicket -TicketID $ticketID `
						-BaseApiUrl $pstrSvrUrl -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			$ticket | Select-Object -ExpandProperty id | Should Be $ticketID;		
		}
		
		It 'gets the id and subject properties of a ticket by using the -Property param' {
			$ticketID = $pstrTicketID;
			$fields = @("id", "summary");
			$ticket = Get-CWServiceTicket -TicketID $ticketID -Property $fields `
				-BaseApiUrl $pstrSvrUrl -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			$ticket.PSObject.Properties | Measure-Object | Select -ExpandProperty Count | Should Be $fields.Count;		
		}
		
		It 'gets tickets by passing array of ticket ids to the -TicketID param' {
			$ticketIDs = $pstrTicketIDs;
			$tickets = Get-CWServiceTicket -TicketID $ticketIDs `
							-BaseApiUrl $pstrSvrUrl -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			$tickets | Measure-Object | Select -ExpandProperty Count | Should Be $ticketIDs.Count;		
		}
		
		It 'gets list of tickets that were piped to the cmdlet' {
			$ticketIDs = $pstrTicketIDs;
			$tickets = $ticketIDs | Get-CWServiceTicket -BaseApiUrl $pstrSvrUrl -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			$tickets | Measure-Object | Select -ExpandProperty Count | Should Be $ticketIDs.Count;		
		}
		
		It 'gets ticket based on the -Filter param' {
			$filter = "id = $pstrTicketID";
			$ticket = Get-CWServiceTicket -Filter $filter `
							-BaseApiUrl $pstrSvrUrl -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			$ticket.id | Should Be $pstrTicketID;		
		}
		
		It 'gets ticket based on the -Filter param and uses the SizeLimit param' {
			$filter = "id IN ($([String]::Join(',', $pstrTicketIDs)))";
			$sizeLimit =  2;
			$tickets = Get-CWServiceTicket -Filter $filter -SizeLimit $sizeLimit -BaseApiUrl $pstrSvrUrl -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			$tickets | Measure-Object | Select -ExpandProperty Count | Should Be $sizeLimit;
		}
		
		It 'gets tickets and sorts ticket id by descending piping cmdlet through Sort-Object cmdlet' {
			$ticketIDs = $pstrTicketIDs;
			$tickets = Get-CWServiceTicket -TicketID $ticketIDs -BaseApiUrl $pstrSvrUrl -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate | Sort -Descending id;
			$maxTicketId = $ticketIDs | Measure-Object -Maximum | Select -ExpandProperty Maximum
			$tickets[0].id | Should Be $maxTicketId;		
		}
		
	} # end of Context 'Get-CWServiceTicket'
	
	Context "New-CWServiceTicket"  {
		
		$pstrTicketCompany  = $pstrProcNewTicket.ticketCompany
		$pstrTicketBoard    = $pstrProcNewTicket.ticketBoard
		$pstrTicketContact  = $pstrProcNewTicket.ticketContact
		$pstrTicketStatus   = $pstrProcNewTicket.ticketStatus
		$pstrTicketPriority = $pstrProcNewTicket.ticketPriority
		$pstrTicketTitle    = $pstrProcNewTicket.ticketTitle
		$pstrTicketBody     = $pstrProcNewTicket.ticketBody
	
		It "create a new service ticket and check for the ticket number" {
			$ticket = New-CWServiceTicket -BoardID $pstrTicketBoard -CompanyID $pstrTicketCompany -ContactID $pstrNewTicketContact `
						-Status $pstrTicketStatus -PriorityID $pstrTicketPriority `
						-Subject $pstrTicketTitle -Description $pstrTicketBody `
						-BaseApiUrl $pstrSvrUrl -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			$ticket.id -gt 0 | Should Be $true; 
		}
		
	} # end of Context "New-CWServiceTicket" 
	
	Context "Update-CWServiceTicket"  {
		
		$pstrTicketID  = $pstrGenSvc.ticketIds[0];
		$pstrStatusID  = $pstrGenSvc.statusIds[0];
		$pstrBoardID   = $pstrGenSvc.boardIds[0];
	
		It "change the status of a ticket" {
			$ticketID = $pstrTicketID;
			$statusID = $pstrStatusID;
			$ticket = Update-CWServiceTicket -TicketID $ticketID -StatusID $statusID `
						-BaseApiUrl $pstrSvrUrl -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			$ticket.status.id -eq $statusID | Should Be $true; 
		}
		
		It "change the status of a ticket and set the board ID" {
			$ticketID = $pstrTicketID;
			$statusID = $pstrStatusID;
			$boardID  = $pstrBoardID;
			$ticket = Update-CWServiceTicket -TicketID $ticketID -StatusID $statusID -BoardID $boardID `
						-BaseApiUrl $pstrSvrUrl -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			$ticket.status.id -eq $statusID -and $ticket.board.id -eq $boardID | Should Be $true; 
		}
		
		It "add a ticket note to a ticket" {
			$ticketID = $pstrTicketID;
			$ticket = Update-CWServiceTicket -TicketID $ticketID `
			            -Message "Testing new ticket note via update ticket command." -AddToDescription `
						-BaseApiUrl $pstrSvrUrl -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			$ticket.id -eq $ticketID | Should Be $true; 
		}
		
	} # end of Context "Update-CWServiceTicket" 
		
} # end of Describe 'CWServiceTicket'