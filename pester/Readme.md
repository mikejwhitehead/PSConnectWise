#Overview

This directory stores the Pester unit tests for the module. Below are the variables it should define.

###Defining Variables for Testing

Define your testing variables in a `.ps1` file named: `'.test.variables.ps1'`

- ConnectWise Server Info
  - `$pstrSvrUrl`
  	 - Example: `https://TechInUrPocket.example.com/v4_6_Release/apis/3.0`
  - `$pstrCompany`
     - Example: `TechInUrPocket`
  - `$pstrSvrPublicKey`
     - Example: `Pub1icK3yH3r3`
  - `$pstrSvrPrivateKey`
     - Example: `Pri@t3K3yH3r3`
- Ticket ID for `Get-` Request
  - `$pstrTicketID`
     - Example: `7617515`
  - `$pstrTicketIDs`
     - Example: `@(7617515, 7738721, 7787839)`

