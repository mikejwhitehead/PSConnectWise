#Overview  

Collection of PowerShell CmdLet that interface with ConnectWise's REST API service.


##CmdLets  
- ConnectWise Service Tickets  
  - `Get-CWServiceTicket`  
  - `Add-CWServiceTicket`  
  - `Remove-CWServiceTicket`  
  - `Update-CWServiceTicket` 

##Classes  
- `WebRestApiClient`  
- `CWApiClientRequest`  
- `CwApiRequestServiceTicket`   


#PS Class Architecture  

##WebRestApiRequest

###Purpose
Wrapper for the `Invoke-RestMethod` CmdLet.

###Contructors
- `WebRestApiRequest(string header, string uri, string relativeEndpointUri, string queryString, string body)`

###Properties  
- Private 
  - n/a
- Public
  - `$Url`
    - purpose: url of the request 
    - type: `string`
  - `$Header`: header for the request
    - type: `hashtable`
  - `$Verb`: the HTTP verb for the request
    - type: `string`
  - `$QueryString`
    - purpose: the query string to be appended to url
    - type: `string`
  - `$Body`
    - purpose: body of the request in JSON
    - type: `string`
  - `Response`
    - purpose: store the reponse from the REST service
    - type: `pscustomobject`
 
###Methods
- Private (Helpers)
  - n/a
- Public 
  - `Invoke()`
    - purpose: brings together all the details of the request then calls PS's `Invoke-RestRequest` 
    - returns: `pscustomobject[] reponse`
  
###Static Methods
- Private (Helpers)
  - `_concateQueryString()`
    - purpose: helper function that determines when to add '?' or '&' to the query string
    - returns: `string queryString`
- Public 
  - `buildQueryString(string property, string value)`
    - purpose: builds the query string for the request
    - returns: `string queryString`
  
  
##CWApiRestClient

###Purpose
Provide a client interface for the ConnectWise REST API endpoints. Creates a new instant of `WebRestApiRequest`, calls its invoke method using information provided, and returns the results.  

###Contructors
- `CWApiClientRequest(string baseUrl, string pathUri, string header, string companyName, string, publicKey, string privateKey)`

###Properties
- Private (Hidden)
  - `$_cwValidQueryStringParameters`
    - purpose: list of valid QueryString parameters for the CW API service
    - type: `hashtable`
- Public 
  - `$HttpBaseUrl`
    - purpose: value the base url (ie "https://cw.connectwise.com")
    - type: `string`
  - `$HttpPathUri`
    - purpose: value of the relative path uri (ie "/service/tickets")
    - type: `string`
  - `$HttpHeader`
    - purpose: stores request header information
    - type: `string`
  - `$CwCompanyName`
    - purpose: name of the ConnectWise company for the request
    - type: `string`
  - `$CwApiPublicKey`
    - purpose: public api key of the ConnectWise member making the request
    - type: `string`
  - `$CwApiPrivateKey`
    - purpose: private api key of the ConnectWise member making the request
    - type: `string`
 
###Methods
- Private (Helpers)
  - `_getCWAuthenticationString()`
    - purpose: combined the public and private API key and Base64 encodes it
    - returns: `string basicAuthString`
  - `_buildCWQueryString(string property, string value)`
    - purpose: builds query string valid CW properties wrapping the `WebRestApiRequest.buildQueryString()` static method.
    - returns: `string queryString`
- Public
  - `Invoke(hashtable requestHashtable)`
    - purpose: invoke the CW REST request and return the results 
    - returns: `pscustomobject[] requestedItems`
    - overloads: 
      - `Invoke(string uri)`
    
##CwApiServiceTicketSvc

###Purpose
Creates a client service for the ConnectWise "Service Tickets" APIs. Inherts from the `CWApiRestClient` class. 

###Contructors
- `CwApiRequestServiceTicket(string baseUrl, string CwCompany, string CwApiPublicKey, string CwApiPrivateKey)`

###Properties
- Private (Hidden)
  - *All Public Properties from `CWApiRestClient`*
- Public 
  - `CWBaseUri`
    - purpose: value of the base url to the CW server for the API requests
    - type: string
  - `CWCompanyName`
    - purpose: value of the CW company name
    - type: string
  - `CWApiPublicKey`
    - purpose: value of the CW memeber's API public key 
    - type: string
  - `CWApiPublicKey`
    - purpose: value of the CW memeber's API private key
    
###Methods
- Private (Helpers)
  - n/a
- Public
  - `Read(int ticketId)`
    - purpose: get ticket(s)
    - returns: `pscustomobject[] cwTickets`
    - overloads:
      - `Read(hashtable filterHashtable)`
      - `Read(int ticketId, string[] fields)`
      - `Read(string ticketQuery)`
      - `Read(string ticketQuery, string[] fields)`
      - `Read(string ticketQuery, string[] fields, int page, int pageSize)`
      - `Read(string ticketQuery, string[] fields, string orderBy)`
      - `Read(string ticketQuery, string[] fields, string orderBy, int page, int pageSize)`
  - `Create(hashtable ticketHashtable)`
    - purpose: create single ticket
    - returns: `pscustomobject cwTicket`
  - `Update(hashtable ticketHashtable)`
    - params: update single ticket
    - returns: `pscustomobject cwTicket`
  - `Delete(int ticketId)`
    - params: delete single ticket
    - returns: `bool isDeleted`
    
#Requirements

- PowerShell 5.0
- ConnectWise Server 2015.3 or Newer
- CW Member's Public and Private API Key
- ConnectWise Service's Base URL for API Request
