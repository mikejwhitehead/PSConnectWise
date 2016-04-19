#PSConnectWise  

Collection of PowerShell functions that interface with ConnectWise's REST API service. This project is meant to target the latest general releases of PowerShell (i.e. PS v5.0) and ConnectWise.

##Functions
Goal of the version of v1.0 was to create the minimum required PowerShell functions that is needed to properly create, read, update, and delete a ConnectWise ticket. 

######Service Module
0. `Get-CWServiceTicket`
0. `Get-CWServiceBoard`
0. `Get-CWServiceBoardStatus`
0. `Get-CWServicePriority`
0. `New-CWServiceTicket`
0. `Get-CWServiceTicketNote`
0. `Add-CWServiceTicketNote`
0. `Remove-CWServiceTicket`
0. `Update-CWServiceTicket`

######Company Module
0. `Get-CWCompany`
0. `Get-CWCompanyContact`
        
        
##Requirements

- PowerShell 5.0
- ConnectWise Server v2015.3 or Newer
- CW Member's Public and Private API Key
- ConnectWise Service's Base URL for API Request

##Import Module to PS Session

0. Download or Clone this Repository
0. Open PowerShell
0. Import the Module (.psm1) within the `PSConnectWise` Directory
   - `Import-Module "...\PSConnectWise\PSConnectWise\PSConnectWise.psm1" -Force;`
0. CmdLets are Imported and Ready to Use

##Examples

####Get ConnectWise Ticket

#####Execute
```powershell
$Server = Get-CWConnectionInfo -Domain "TechInUrPocket.example.com" -CompanyName "TechInUrPocket" -PublicKey 'Pub1icK3yH3r3' -PrivateKey 'Pri@t3K3yH3r3';`
Get-CWServiceTicket -TicketID 1234567 -Server $Server;
```
#####Returns
```powershell
id                         : 1234567
summary                    : My Computer is Broken
recordType                 : ServiceTicket
board                      : @{id=1; name=BreakFix; _info=}
status                     : @{id=1; name=New; _info=}
... 
```


##Extra Information
- The *pester* Directory Stores the Unit Test Scripts
  - See [Readme](https://github.com/sgtoj/ConnectWisePSModule/tree/master/pester)
- [Documented Architecture](https://github.com/sgtoj/ConnectWisePSModule/blob/master/doc/ClassArchitectures.md) of the Dependent PS Classes
  - It is not required to read or understand it to use PowerShell CmdLets.
  - Its target is future contributors to this project.
