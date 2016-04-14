#Readme  

Collection of PowerShell CmdLet that interface with ConnectWise's REST API service. This project is meant to target the latest general releases of PowerShell and ConnectWise.

##Roadmap for v1.0.0 
Milestone Requirement: Create the minimum required CmdLets that is needed to properly create, read, update, and delete a ConnectWise ticket. 

###CmdLets
0. `Get-CWServiceTicket`
  - CmdLet: **Completed**
  - Documentation: *Not Completed*
0. `Get-CWServiceBoard`
  - CmdLet: **Completed**
  - Documentation: *Not Completed*
0. `Get-CWServiceBoardStatus`
  - CmdLet: **Completed**
  - Documentation: *Not Completed*
0. `Get-CWServicePriority`
  - CmdLet: **Completed** (*Not Tested Yet*)
  - Documentation: *Not Completed*
0. `New-CWServiceTicket`
  - CmdLet: **Completed**
  - Documentation: *Not Completed*
0. `Get-CWServiceTicketNote`
  - CmdLet: **Completed**
  - Documentation: *Not Completed*
0. `Add-CWServiceTicketNote`
  - CmdLet: **Completed**
  - Documentation: *Not Completed*
0. `Remove-CWServiceTicket`
  - CmdLet: **Completed**
  - Documentation: *Not Completed*
0. `Update-CWServiceTicket`
  - CmdLet: **Completed**
  - Documentation: *Not Completed*
0. `Get-CWCompany`
  - CmdLet: **Completed**
  - Documentation: *Not Completed*
0. `Get-CWCompanyContact`
  - CmdLet: *Not Completed*
  - Documentation: *Not Completed*
        
###Other
0. Document All CmdLets
0. Rename **pester** to **test**
0. Create a Module Manifest
0. Expand on the Examples
        
#Requirements

- PowerShell 5.0
- ConnectWise Server v2015.3 or Newer
- CW Member's Public and Private API Key
- ConnectWise Service's Base URL for API Request

#Example

###Import Module for the current PS Session
0. Download or Clone this Repository
   -  Or [Download](https://github.com/sgtoj/ConnectWisePSModule/tree/master/src) Only the  `ConnectWisePSModule.psm1` Module File
0. Open PowerShell
0. Import the Module (.psm1) within the `scr` Directory
   - `Import-Module "C:\Path\To\ConnectWisePSModule\scr\ConnectWisePSModule.psm1" -Force;`
0. CmdLets are Imported and Ready to Use

### Get ConnectWise Ticket
0. Open PS and Import Module (*see above*)
0. Execute in PowerShell:
   - `Get-CWServiceTicket -TicketID 1234567 -BaseApiUrl "https://TechInUrPocket.example.com/v4_6_Release/apis/3.0" -CompanyName "TechInUrPocket" -PublicKey 'Pub1icK3yH3r3' -PrivateKey 'Pri@t3K3yH3r3';`

#Extra Information
- There is no module manifest until initial v1.0.0 milestones are meet. 
- The *pester* Directory Stores the Unit Test Scripts
  - See [Readme](https://github.com/sgtoj/ConnectWisePSModule/tree/master/pester)
- [Documented Architecture](https://github.com/sgtoj/ConnectWisePSModule/blob/master/doc/ClassArchitectures.md) of the Dependent PS Classes
  - It is not required to read or understand it to use PowerShell CmdLets.
  - Its target is future contributors to this project.
