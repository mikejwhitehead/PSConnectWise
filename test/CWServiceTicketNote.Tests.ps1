# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "PSConnectWise" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\PSConnectWise\PSConnectWise.psm1" -Force 

Describe 'CWServiceTicketNote' {
	
	. "$WorkspaceRoot\test\LoadTestSettings.ps1"
	
	# get the server connnection
	$pstrServer = Get-CWConnectionInfo -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
	
	Context 'Get-CWServiceTicketNote' {
		
		$pstrTicketID  = $pstrGenSvc.ticketIds[0];
		$pstrNoteID    = $pstrGenSvc.ticketNoteIds[0];
	
		It 'gets ticket note entries for a ticket and check that the results is an array' {
			$ticketID = $pstrTicketID;
			$timeEntries = Get-CWServiceTicketNote -TicketID $ticketID -Server $pstrServer;
			$timeEntries.GetType().BaseType.Name | Should Be "Array";		
		}
		
		It 'gets a single note from a ticket and pipes it through the Select-Object cmdlet for the id property of the first object' {
			$noteID = $pstrNoteID;
			$ticketID = $pstrTicketID;
			$note = Get-CWServiceTicketNote -TicketID $ticketID -NoteID $noteID -Server $pstrServer | Select-Object -First 1;
			$note | Select-Object -ExpandProperty ticketID | Should Be $ticketID;		
		}
		
	}
	
	Context 'Add-CWServiceTicketNote' {
		
		$pstrTicketID  = $pstrGenSvc.ticketIds[0];
		
		It 'add a new ticket note to a ticket then checks the return object for the ticket id' {
			$ticketID = $pstrTicketID;
			$message = "Testing the ability to add note entries to a ticket via new ticket note command."
			$note = Add-CWServiceTicketNote -TicketID $ticketID -Message $message -Server $pstrServer;
			$note | Select-Object -ExpandProperty ticketId | Should Be $ticketID;	
		}
		
	}
	
} 