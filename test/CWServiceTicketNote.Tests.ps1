# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "CWServiceBoardStatusCmdLets" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\src\CWServiceTicketNoteCmdLets.psm1" -Force 

Describe 'CWServiceTicketNote' {
	
	. "$WorkspaceRoot\test\LoadTestSettings.ps1"
	
	Context 'Get-CWServiceTicketNote' {
		
		$pstrTicketID  = $pstrGenSvc.ticketIds[0];
		$pstrNoteID    = $pstrGenSvc.ticketNoteIds[0];
	
		It 'gets ticket note entries for a ticket and check that the results is an array' {
			$ticketID = $pstrTicketID;
			$timeEntries = Get-CWServiceTicketNote -TicketID $ticketID -BaseApiUrl $pstrSvrUrl -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			$timeEntries.GetType().BaseType.Name | Should Be "Array";		
		}
		
		It 'gets a single note from a ticket and pipes it through the Select-Object cmdlet for the id property of the first object' {
			$noteID = $pstrNoteID;
			$ticketID = $pstrTicketID;
			$note = Get-CWServiceTicketNote -TicketID $ticketID -NoteID $noteID -BaseApiUrl $pstrSvrUrl -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate | Select-Object -First 1;
			$note | Select-Object -ExpandProperty ticketID | Should Be $ticketID;		
		}
		
		It 'add a new ticket note to a ticket then checks the return object for the ticket id' {
			$ticketID = $pstrTicketID;
			$message = "Testing the ability to add note entries to a ticket via new ticket note command."
			$note = Add-CWServiceTicketNote -TicketID 7857582 -Message $message -BaseApiUrl $pstrSvrUrl -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
			$note | Select-Object -ExpandProperty ticketId | Should Be $ticketID;	
		}
		
	}
	
} 