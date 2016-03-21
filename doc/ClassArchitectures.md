#PS Classes Overview  

- `WebRestApiClient`  
- `CWApiRequestInfo`
- `CWApiClientRequest`  
- `CwApiRequestServiceTicket`   

#PS Class Architecture  

##WebRestApiRequest

###Purpose
Wrapper for the `Invoke-RestMethod` CmdLet.

###Contructors
- `WebRestApiRequest(hashtable header, string url, string verb, string body)`

###Properties  
- Private 
  - `contentType`
    - purpose: web request's content type normally placed in the HTTP header
    - default: `application/json`
    - type: `string`
- Public
  - `Url`
    - purpose: url of the request 
    - type: `string`
  - `Header`: header for the request
    - type: `hashtable`
  - `Verb`: the HTTP verb for the request
    - type: `string`
  - `Body`
    - purpose: body of the request in JSON
    - type: `string`
  - `Response`
    - purpose: store the reponse from the REST service
    - type: `pscustomobject`
 
###Methods
- Private (Helpers)
  - `_validateWebRequestParams()`
  - purpose: checks the properties of the request to ensure all required properties are set
  - returns: `void`
- Public 
  - `Invoke()`
    - purpose: brings together all the details of the request then calls PS's `Invoke-RestRequest` 
    - returns: `pscustomobject[] reponse`
  
###Static Methods
- Private (Helpers)
  - `_concateQueryString(string uriPathAndQuery, string subJoinQuery)`
    - purpose: helper function that determines when to add '?' or '&' to the query string
    - returns: `string queryString`
- Public 
  - `BuildQueryString(hashtable queryParams)`
    - purpose: builds the query string for the request
    - returns: `string queryString`
  

##CWApiRequestInfo

###Purpose
Simple object that holds the relative information for the CW API request. It is used by service objects (ie `CwApiServiceTicketSvc`) and consumed by the `CWApiRestClient` class.

###Constructors
- `CWApiRestRequestInfo()`

###Properties
- Private (Hidden)
  - n/a
- Public 
  - `RelativePathUri`
    - purpose: descibes the relative path URI to concat with base URL and path strings
    - type: `string`
  - `QueryString`
    - purpose: holds query string of the requested URL
    - type: `string`
  - `Verb`
    - purpose: name of the HTTP verb for the request 
    - type: `string`
  - `Body`
    - purpose: body of the request that is a string in JSON format
    - type: `string`

###Methods
- Private (Helpers)
  - n/a
- Public
  - n/a
 
  
##CWApiRestClient

###Purpose
Provide a client interface for the ConnectWise REST API endpoints. Creates a new instant of `WebRestApiRequest`, calls its invoke method using information provided, and returns the results.  

###Contructors
- `CWApiRestClient(string baseUrl, string pathUri, string companyName, string, publicKey, string privateKey)`
- `CWApiRestClient(string baseUrl, string pathUri, hashtable header, string companyName, string, publicKey, string privateKey)`

###Properties
- Private (Hidden)
  - `_headerAthenticationString`
    - purpose: base64 encoded string for the authentication property in the HTTP header
    - type: `string`
- Public 
  - `HttpBaseUrl`
    - purpose: value the base url (ie "https://cw.connectwise.com")
    - type: `string`
  - `HttpBasePathUri`
    - purpose: value of the relative path uri (ie "/service/tickets")
    - type: `string`
  - `HttpHeader`
    - purpose: stores request header information
    - type: `string`
  - `CwCompanyName`
    - purpose: name of the ConnectWise company for the request
    - type: `string`
  - `CwApiPublicKey`
    - purpose: public api key of the ConnectWise member making the request
    - type: `string`
  - `CwApiPrivateKey`
    - purpose: private api key of the ConnectWise member making the request
    - type: `string`
 
###Methods
- Private (Helpers)
  - `transformHttpHeader(hashtable header)`
    - purpose: transfer the default http header using the inform in the `header` param
    - returns: `void`
  - `_validateCWApiRequestParams()`
    - purpose: checks the properties of the request to ensure all required properties are set
    - returns: `void`
  - `_createCWAuthenticationString()`
    - purpose: combined the public and private API key and Base64 encodes it
    - returns: `string basicAuthString`
  - `_buildHttpHeader()`
    - purpose: builds the default HTTP header hastable
    - returns: `hashtable header`
- Public
  - `Request(CWApiRequestInfo request)`
    - purpose: consumes the `CWApiRequestInfo` object, uses it information to invoke the CW REST request and return the results 
    - returns: `pscustomobject[] requestedItems`
    - overloads: 
      - `Invoke(string uri)`
  - `BuildCWQueryString(hashtable queryParams)`
    - purpose: builds the query string for the request for only CW valid parameters
    - returns: `string`
  - `BuildUrl(string relativePathUri, string queryString)`
    - purpose: builds the complete URL for a request
    - returns: `string`
      
###Static Methods    
- Private
  - n/a
- Public
  - `_buildCWQueryString(string property, string value)`
    - purpose: builds query string valid CW properties wrapping the `WebRestApiRequest.buildQueryString()` static method.
    - returns: `string queryString`
    
##CwApiServiceTicketSvc

###Purpose
Creates a client service for the ConnectWise "Service Tickets" APIs. Inherts from the `CWApiRestClient` class. 

###Contructors
- `CwApiServiceTicketSvc(string baseUrl, string companyName, string publicKey, string privateKey)`

###Properties
- Private (Hidden)
  - n/a
- Public 
  - `CWApiClient`
    - purpose: reference to the CW API client
    - type: `CWApiRestClient`
    
###Methods
- Private (Helpers)
  - n/a
- Public
  - `ReadTicket(int ticketId)`
    - purpose: get ticket
    - returns: `pscustomobject[] cwTickets`
    - overloads: 
      - `ReadTicket(int ticketId, string[] fields)`
  - `ReadTickets(hashtable filterHashtable)`
    - purpose: get tickets
    - returns: `pscustomobject[] cwTickets`
    - overloads:
      - `ReadTickets(string ticketFilter)`
      - `ReadTickets(string ticketFilter, string[] fields)`
      - `ReadTickets(string ticketFilter, string[] fields, int32 page, int32 pageSize)`
      - `ReadTickets(string ticketFilter, string[] fields, string orderBy)`
      - `ReadTickets(string ticketFilter, string[] fields, string orderBy, int page, int pageSize)`
  - `GetTicketCount(string ticketConditions)` 
    - purpose: gets the count of tickets that meets the conditions
    - returns: `uint32`
  - `CreateTicket(hashtable ticketHashtable)` - *Not Implemented*
    - purpose: create single ticket
    - returns: `pscustomobject cwTicket`
  - `UpdateTicket(hashtable ticketHashtable)` - *Not Implemented*
    - params: update single ticket
    - returns: `pscustomobject cwTicket` 
  - `DeleteTicket(int ticketId)` - *Not Implemented*
    - params: delete single ticket
    - returns: `bool isDeleted`

##CwApiServiceBoardSvc

###Purpose
Creates a client service for the ConnectWise "Service Boards" APIs. Inherts from the `CWApiRestClient` class. 

###Contructors
- `CwApiServiceBoardSvc(string baseUrl, string companyName, string publicKey, string privateKey)`

###Properties
- Private (Hidden)
  - n/a
- Public 
  - `CWApiClient`
    - purpose: reference to the CW API client
    - type: `CWApiRestClient`
    
###Methods
- Private (Helpers)
  - n/a
- Public
  - `ReadBoard(int boardID)`
    - purpose: get board
    - returns: `pscustomobject[] cwBoards`
  - `ReadBoards(hashtable filterHashtable)`
    - purpose: get board
    - returns: `pscustomobject[] cwBoards`
    - overloads:
      - `ReadBoards(string boardFilter)`
      - `ReadBoards(string boardFilter, int32 page, int32 pageSize)`
      - `ReadBoards(string boardFilter, string orderBy)`
      - `ReadBoards(string boardFilter, string orderBy, int page, int pageSize)`
  - `GetBoardCount(string boardFilter)` 
    - purpose: gets the count of board that meets the conditions
    - returns: `uint32`