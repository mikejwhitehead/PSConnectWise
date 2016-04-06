# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "CWServiceTicketCmdLets" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\src\CWServiceTicketCmdLets.psm1" -Force 

# dot-sources the definition file to get static variables (prefixed with 'pstr') to be used for testing
. "$WorkspaceRoot\pester\.test.variables.ps1" 

Describe 'CWServiceTicket' {
	
	Context 'Get-CWServiceTicket' {
	
		It 'gets ticket and checks for the id field' {
			$ticketID = $pstrTicketID;
			$ticket = Get-CWServiceTicket -TicketID $ticketID -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
			$ticket.id | Should Be $ticketID;		
		} 
		
		It 'gets ticket and pipes it through the Select-Object cmdlet for the id property' {
			$ticketID = $pstrTicketID;
			$ticket = Get-CWServiceTicket -TicketID $ticketID -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
			$ticket | Select-Object -ExpandProperty id | Should Be $ticketID;		
		}
		
		It 'gets the id and subject properties of a ticket by using the -Property param' {
			$ticketID = $pstrTicketID;
			$fields = @("id", "summary");
			$ticket = Get-CWServiceTicket -TicketID $ticketID -Property $fields -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
			$ticket.PSObject.Properties | Measure-Object | Select -ExpandProperty Count | Should Be $fields.Count;		
		}
		
		It 'gets tickets by passing array of ticket ids to the -TicketID param' {
			$ticketIDs = $pstrTicketIDs;
			$tickets = Get-CWServiceTicket -TicketID $ticketIDs -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
			$tickets | Measure-Object | Select -ExpandProperty Count | Should Be $ticketIDs.Count;		
		}
		
		It 'gets list of tickets that were piped to the cmdlet' {
			$ticketIDs = $pstrTicketIDs;
			$tickets = $ticketIDs | Get-CWServiceTicket -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
			$tickets | Measure-Object | Select -ExpandProperty Count | Should Be $ticketIDs.Count;		
		}
		
		It 'gets ticket based on the -Filter param' {
			$filter = "id = $pstrTicketID";
			$ticket = Get-CWServiceTicket -Filter $filter -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
			$ticket.id | Should Be $pstrTicketID;		
		}
		
		It 'gets ticket based on the -Filter param and uses the SizeLimit param' {
			$filter = "id IN ($([String]::Join(",", $pstrTicketIDs)))";
			$sizeLimit =  2;
			$tickets = Get-CWServiceTicket -Filter $filter -SizeLimit $sizeLimit -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
			$tickets | Measure-Object | Select -ExpandProperty Count | Should Be $sizeLimit;
		}
		
		It 'gets tickets and sorts ticket id by descending piping cmdlet through Sort-Object cmdlet' {
			$ticketIDs = $pstrTicketIDs;
			$tickets = Get-CWServiceTicket -TicketID $ticketIDs -BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey | Sort -Descending id;
			$maxTicketId = $ticketIDs | Measure-Object -Maximum | Select -ExpandProperty Maximum
			$tickets[0].id | Should Be $maxTicketId;		
		}
		
	} # end of Context 'Get-CWServiceTicket'
	
	Context "New-CWServiceTicket"  {
	
		It "create a new service ticket and check for the ticket number" {
			$ticket = New-CWServiceTicket -BoardID $pstrNewTicketBoard -CompanyID $pstrNewTicketCompany -ContactID $pstrNewTicketContact `
						-Status $pstrNewTicketStatus -PriorityID $pstrNewTicketPriority `
						-Subject $pstrNewTicketTitle -Description $pstrNewTicketBody `
						-BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
			$ticket.id -gt 0 | Should Be $true; 
		}
		
	} # end of Context "New-CWServiceTicket" 
	
	# Context "Update-CWServiceTicket"  {
	
	# 	It "change the status of a ticket" {
	# 		$ticketID = $pstrTicketID;
	# 		$ticket = Update-CWServiceTicket -TicketID $ticketID -StatusID $pstrStatus1 
	# 					-BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
	# 		$ticket.status.id -gt $pstrStatus1 | Should Be $true; 
	# 	}
		
	# 	It "change the status of a ticket and set the board ID" {
	# 		$ticketID = $pstrTicketID;
	# 		$ticket = Update-CWServiceTicket -TicketID $ticketID -StatusID $pstrStatus2 -BoardID $pstrBoard `
	# 					-BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
	# 		$ticket.status.id -gt $pstrStatus1 -and $ticket.board.id -gt $pstrBoard | Should Be $true; 
	# 	}
		
	# 	It "add a ticket note to a ticket" {
	# 		$ticketID = $pstrTicketID;
	# 		$ticket = Update-CWServiceTicket -TicketID $ticketID 
	# 		            -Message "Testing new ticket note via update ticket command." -Description
	# 					-BaseApiUrl $pstrSvrUrl -CompanyName $pstrCompany -PublicKey $pstrSvrPublicKey -PrivateKey $pstrSvrPrivateKey;
	# 		$ticket.id -eq $pstrTicketID | Should Be $true; 
	# 	}
		
	# } # end of Context "Update-CWServiceTicket" 
		
} # end of Describe 'CWServiceTicket'