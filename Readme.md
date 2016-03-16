#Description  

Collection of PowerShell CmdLet that interface with ConnectWise's REST API service. This project is meant to target the latest general releases of PowerShell and ConnectWise.

##CmdLets Overview 
- ConnectWise Service Tickets  
  - `Get-CWServiceTicket`
    - **Use Case**: Gets ticket(s) via the ticket number, array of ticket numbers, or query.
    - **Features**
      - Request for specific CW ticket fields (ie id, summary, etc).
      - Accepted ticket ids via the pipe.
  - `Add-CWServiceTicket` 
    - **_Not Implemented Yet_**
  - `Remove-CWServiceTicket` 
    - **_Not Implemented Yet_** 
  - `Update-CWServiceTicket` 
    - **_Not Implemented Yet_** 

#Other
- [Documented Architecture](https://github.com/sgtoj/ConnectWisePSModule/blob/master/doc/ClassArchitectures.md) of the Dependent PS Classes
  - It is not required to read or understand it to use PowerShell CmdLets.
  - Its target is future contributors to this project. 
        
#Requirements

- PowerShell 5.0
- ConnectWise Server v2015.3 or Newer
- CW Member's Public and Private API Key
- ConnectWise Service's Base URL for API Request

#How To Use

##Importing Module to PowerShell

###Importing Module for the current PS Session
0. Download this Repository
0. Open PowerShell
0. Import the Module (.psm1) within the `scr` Directory
   - `Import-Module "C:\Path\To\ConnectWisePSModule\scr\ConnectWisePSModule.psm1" -Force;`
0. CmdLets are Imported and Ready to Use

##Using CmdLets

### OneLiner Example
0. Open PS and Import Module (*see above*)
0. Execute in PowerShell:
   - `Get-CWServiceTicket -TicketID 1234567 -BaseApiUrl "https://TechInUrPocket.example.com/v4_6_Release/apis/3.0" -CompanyName "TechInUrPocket" -PublicKey 'Pub1icK3yH3r3' -PrivateKey 'Pri@t3K3yH3r3';`

#Creating CW Memeber API Keys

 Please visit the [ConnectWise Developer](https://developer.connectwise.com/) site or contact ConnectWise Support for any questions and issues with ConnectWise service or their API. 

##Create Keys for Normal Memeber

0. Go to Respective Memeber's 'My Account' Page
   ![My Account Link](https://raw.githubusercontent.com/sgtoj/ConnectWisePSModule/master/doc/imgs/createapikey-1.png)
0. Click on the API Key Tab
   ![My Account Link](https://raw.githubusercontent.com/sgtoj/ConnectWisePSModule/master/doc/imgs/createapikey-2.png)
0. Click on the Plus Button to Add a New Key
   ![My Account Link](https://raw.githubusercontent.com/sgtoj/ConnectWisePSModule/master/doc/imgs/createapikey-3.png)
0. Add a Description and Click on the Save Button
   ![My Account Link](https://raw.githubusercontent.com/sgtoj/ConnectWisePSModule/master/doc/imgs/createapikey-4.png)
0. Write Down Public and Private Keys

*__Note__: Same account restrictions that apply for the member in the ConnectWise Client will apply through the API too. In the above example, it shows how to create a API key for a normal ConnectWise member. However, an 'API Member Only' memeber can be created.*

