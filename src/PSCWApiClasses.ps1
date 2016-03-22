class WebRestApiRequest
{
    # public properties
    [string] $Url;
    [hashtable] $Header;  
    [string] $Verb; 
    [string] $Body;
    [pscustomobject[]] $Response;
    
    # private properties
    hidden [string] $contentType = "application/json";
    
    WebRestApiRequest([hashtable] $header, [string] $url, [string] $verb, [string] $body)
    {
        $this.Url    = $url;
        $this.Header = $header;
        $this.Verb   = $verb;
        $this.Body   = $body;
        
        $this._validateWebRequestParams();
    }
    
    [pscustomobject] Invoke() 
    {
        if ([String]::IsNullOrWhiteSpace($this.Body))
        {
            Write-Debug "REST Request Details:  $($this | Select Url, Header, Verb | ConvertTo-Json -Depth 10 | Out-String)"
            $this.Response = Invoke-RestMethod -Uri $this.Url -Method $this.Verb -Headers $this.Header -ContentType $this.contentType;   
        }
        else
        {
            Write-Debug "REST Request Details:  $($this | Select Url, Header, Verb, Body | ConvertTo-Json -Depth 10 | Out-String)"
            $this.Response = Invoke-RestMethod -Uri $this.Url -Method $this.Verb -Headers $this.Header -Body $this.Body -ContentType $this.contentType;       
        }
        
        return $this.Response;
    }
    
    hidden [void] _validateWebRequestParams()
    {
        [string[]] $requiredProperties = @("Url", "Header", "Verb");
        
        Write-Debug $("Checking if required WebRestApiRequest properties are not null or empty.");
        
        foreach ($p in $requiredProperties)
        {
            if([String]::IsNullOrWhiteSpace($this.PSObject.Properties[$p].Value))
            {
                Write-Error -Message "Property is null or empty" -Category InvalidArgument -TargetObject $p.Name;
            }
        }
        
    }
    
    static [string] BuildQueryString([hashtable] $queryParams)
    {
        [string] $queryString = "";
        
        foreach ($p in $queryParams.GetEnumerator())
        {
            if ($p.Value -eq $null)
            {
                continue;    
            }
            
            $subQuery = [String]::Format("{0}={1}", $p.Key, $p.Value);
            $queryString = [WebRestApiRequest]::_concateQueryString($queryString, $subQuery);
        }
        
        return $queryString;
    }
    
    static hidden [string] _concateQueryString([string] $queryString, [string] $subJoinQuery)
    {
        #check if the resource and query section of the uri already started the query (via '?')
        if ([RegEx]::IsMatch($queryString, "\?"))
        {
            $queryString += [string]("&" + $subJoinQuery);
        }
        else
        {
            $queryString += [string]("?" + $subJoinQuery);
        }

        return $queryString;
    }
    
}

class CWApiRequestInfo
{
    # this acts more like stuct than a class
    # it holds the request information used by the CWApiRestClient class
    
    [string] $RelativePathUri;
    [string] $QueryString;
    [string] $Verb;
    [string] $Body;
    
}


class CWApiRestClient 
{
    # public properties
    [string] $HttpBaseUrl;
    [string] $HttpBasePathUri;
    [hashtable] $HttpHeader;
    [string] $CWCompanyName;
    [string] $CWApiPublicKey;
    [string] $CWApiPrivateKey;
    
    # private properties
    hidden [string] $_headerAthenticationString;
    
    CWApiRestClient ([string] $baseUrl, [string] $companyName, [string] $publicKey, [string] $privateKey)
    {
        $this.HttpBaseUrl = $baseUrl;
        $this.HttpBasePathUri = "";
        $this.CWCompanyName = $companyName;
        $this.CWApiPublicKey = $publicKey;
        $this.CWApiPrivateKey = $privateKey;
        
        $this._validateCWApiRequestParams();
        $this.HttpHeader = $this._buildHttpHeader();
    }
    
    CWApiRestClient ([string] $baseUrl, [string] $pathUri, [string] $companyName, [string] $publicKey, [string] $privateKey)
    {
        $this.HttpBaseUrl = $baseUrl;
        $this.HttpBasePathUri = $pathUri;
        $this.CWCompanyName = $companyName;
        $this.CWApiPublicKey = $publicKey;
        $this.CWApiPrivateKey = $privateKey;
        
        $this._validateCWApiRequestParams();
        $this.HttpHeader = $this._buildHttpHeader();
    }
    
    CWApiRestClient ([string] $baseUrl, [string] $pathUri, [hashtable] $header, [string] $companyName, [string] $publicKey, [string] $privateKey)
    {
        $this.HttpBaseUrl = $baseUrl;
        $this.HttpBasePathUri = $pathUri;
        $this.CWCompanyName = $companyName;
        $this.CWApiPublicKey = $publicKey;
        $this.CWApiPrivateKey = $privateKey;
        
        $this._validateCWApiRequestParams();
        $this.HttpHeader = $this._buildHttpHeader();
        
        transformHttpHeader($header);
    }
    
    [pscustomobject] Get ([string] $url)
    {
        $header = $this.HttpHeader;
        $verb   = "GET";
        
        return $this._request($header, $url, $verb, $null);
    }
    
    [pscustomobject] Get ([CWApiRequestInfo] $request)
    {
        $header = $this.HttpHeader;
        $url    = $this.BuildUrl($request.RelativePathUri, $request.QueryString);
        $verb   = "GET"
        
        if ($request.QueryString -ne $null)
        {
            $body = $request.Body | ConvertTo-Json -Depth 100 | Out-String; 
        }
        else
        {
            $body = $null;     
        }
        
        return $this._request($header, $url, $verb, $body);
    }
    
    static hidden [string] buildCWQueryString ([hashtable] $queryParams)
    {
        [string[]] $validParams = @("fields", "page", "pagesize", "orderby", "conditions");
        [string] $queryString = "";
        [hashtable] $vettedQueryParams = @{}
        
        foreach ($p in $queryParams.GetEnumerator())
        {
            if ($p.Key -notin $validParams)
            {
                Write-Warning "Invalid query parameter found: $($p.Key). It was not added to the query string.";
                continue;
            }
            
            $vettedQueryParams.Add($p.Key, $p.Value);   
        } 
       
        if ($vettedQueryParams.Count -gt 0)
        {
           $queryString = [WebRestApiRequest]::BuildQueryString($vettedQueryParams);
        }
        
        return $queryString;
    }    
        
    [string] BuildUrl ([string] $relativePathUri, [string] $queryString)
    {
        if ([string]::IsNullOrEmpty($relativePathUri))
        {
            $relativePathUri = "";
        }
        
        if ([string]::IsNullOrEmpty($queryString))
        {
            $queryString = "";
        }
        
        $url = [String]::Format("{0}{1}{2}{3}", $this.HttpBaseUrl, $this.HttpBasePathUri, $relativePathUri, $queryString);
        
        return $url
    }
    
    hidden [void] transformHttpHeader ([hashtable] $transformHeaderHashtable)
    {
        foreach ($p in $transformHeaderHashtable)
        {
            if ($this.HttpHeader.Contains($p.Key))
            {
                $this.HttpHeader[$p.Key];
            }    
            else 
            {
                $this.HttpHeader.Add($p.Key, $p.Value);
            }
        }
    }
    
    hidden [hashtable] _buildHttpHeader () 
    {
        $header = [hashtable] @{
            "Authorization"    = $this._createCWAuthenticationString();
            "Accept"           = "application/vnd.connectwise.com+json; version=v2015_3";
            "Type"             = "application/json"; 
            "x-cw-overridessl" = "True";
        }
        
        return $header;
    }
    
    [pscustomobject] _request ($header, $url, $verb, $body)
    {
        $client = [WebRestApiRequest]::new($header, $url, $verb, $body);
        $response = $client.Invoke();
        return $response;
    }

    hidden [string] _createCWAuthenticationString ()
    {   
        [string] $encodedString = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}+{1}:{2}" -f $this.CWCompanyName, $this.CWApiPublicKey, $this.CWApiPrivateKey)));
        return [String]::Format("Basic {0}", $encodedString);
    }
    
    hidden [void] _validateCWApiRequestParams ()
    {
        [string[]] $requiredProperties = @("HttpBaseUrl", "CWCompanyName", "CWApiPublicKey", "CWApiPrivateKey");
        
        Write-Debug $("Checking if required CWApiRestClient properties are not null or empty.");
        
        foreach ($p in $requiredProperties)
        {
            if([String]::IsNullOrWhiteSpace($this.PSObject.Properties[$p].Value))
            {
                Write-Error -Message "Property is null or empty" -Category InvalidArgument;
            }
        }
        
    }
}

class CWApiRestClientSvc
{
    hidden [CWApiRestClient] $CWApiClient; 
    
    CWApiRestClientSvc([string] $baseUrl, [string] $companyName, [string] $publicKey, [string] $privateKey)
    {
        $this.CWApiClient = [CWApiRestClient]::new($baseUrl, $companyName, $publicKey, $privateKey);
    }
    
    hidden [pscustomobject[]] QuickRead([string] $url)
    {
        return $this.CWApiClient.Get($url);
    }
    
    hidden [pscustomobject[]] read([string] $relativePathUri, [hashtable] $queryHashtable)
    {
        $MAX_PAGE_REQUEST_SIZE = 50;
        
        $request = [CWApiRequestInfo]::new();
        $request.RelativePathUri = $RelativePathUri
        $request.Verb = "GET"; 
        
        if ($queryHashtable -ne $null)
        {
            if ($queryHashtable.Contains('pageSize') -and $queryHashtable['pageSize'] -eq 0)
            {
                $queryHashtable['pageSize'] = $MAX_PAGE_REQUEST_SIZE;
            }
            [string] $queryString = [CWApiRestClient]::buildCWQueryString($queryHashtable);
            
            $request.QueryString = $queryString;
        }
        
        $items = $this.CWApiClient.Get($request);
        return $items
    }
    
    hidden [uint32] getCount([string] $conditions)
    {        
        return $this.getCount($conditions, "/count")
    }
    
    hidden [uint32] getCount([string] $conditions, [string] $relativePathUri)
    {
        [hashtable] $queryParams = @{
            conditions = $conditions;
        }
        [string] $queryString = [CWApiRestClient]::buildCWQueryString($queryParams)
        
        $response = $this.read($relativePathUri, $queryParams)[0];
        return [uint32] $response.count;
    }
}

class CwApiServiceTicketSvc : CWApiRestClientSvc
{
    CwApiServiceTicketSvc([string] $baseUrl, [string] $companyName, [string] $publicKey, [string] $privateKey) : base($baseUrl, $companyName, $publicKey, $privateKey)
    {
        $this.CWApiClient.HttpBasePathUri = "/service/tickets";
    }
    
    [pscustomobject] ReadTicket([int] $ticketId)
    {
        return $this.ReadTicket($ticketId, "*");
    }
    
    [pscustomobject] ReadTicket([int] $ticketId, [string[]] $fields)
    {
        [hashtable] $queryHashtable = @{ 
            fields = ([string] [String]::Join(",", $fields)).TrimEnd(",");
        }
        
        $relativePathUri = "/$ticketID";
        
        return $this.read($relativePathUri, $queryHashtable);
    }
    
    [pscustomobject[]] ReadTickets([string] $ticketConditions)
    {
        return $this.ReadTickets($ticketConditions, "*");
    }
    
    [pscustomobject[]] ReadTickets([string] $ticketConditions, [string[]] $fields)
    {        
        return $this.ReadTickets($ticketConditions, $fields, 1);
    }
    
    [pscustomobject[]] ReadTickets([string] $ticketConditions, [string[]] $fields, [uint32] $pageNum)
    {        
        return $this.ReadTickets($ticketConditions, $fields, 1, 0);
    }
    
    [pscustomobject[]] ReadTickets([string] $ticketConditions, [string[]] $fields, [uint32] $pageNum, [uint32] $pageSize)
    {
        [hashtable] $queryParams = @{
            conditions = $ticketConditions
            fields     = ([string] [String]::Join(",", $fields)).TrimEnd(",");
            page       = $pageNum;
            pageSize   = $pageSize;
        }
        
        return $this.read($null, $queryParams);
    }
    
    [uint32] GetTicketCount([string] $ticketConditions)
    {
        return $this.getCount($ticketConditions);
    }
    
}

class CwApiServiceBoardSvc : CWApiRestClientSvc
{
    CwApiServiceBoardSvc([string] $baseUrl, [string] $companyName, [string] $publicKey, [string] $privateKey) : base($baseUrl, $companyName, $publicKey, $privateKey)
    {
        $this.CWApiClient.HttpBasePathUri = "/service/boards";;
    }
    
    [pscustomobject] ReadBoard([int] $boardId)
    {
        $relativePathUri = "/$boardId";
        return $this.read($relativePathUri, $null);
    }
    
    [pscustomobject[]] ReadBoards([string] $boardConditions)
    {        
        return $this.ReadBoards($boardConditions, 1);
    }
    
    [pscustomobject[]] ReadBoards([string] $boardConditions, [uint32] $pageNum)
    {         
        return $this.ReadBoards($boardConditions, 1, 0);
    }
    
    [pscustomobject[]] ReadBoards([string] $boardConditions, [uint32] $pageNum, [uint32] $pageSize)
    {
        [hashtable] $queryHashtable = @{
            conditions = $boardConditions
            page       = $pageNum;
            pageSize   = $pageSize;
        }
        
        return $this.read($null, $queryHashtable);
    }
    
    [uint32] GetBoardCount([string] $boardConditions)
    {
        return $this.getCount($boardConditions);
    }
    
}

class CwApiServiceBoardStatusSvc : CWApiRestClientSvc
{
    CwApiServiceBoardStatusSvc([string] $baseUrl, [string] $companyName, [string] $publicKey, [string] $privateKey) : base($baseUrl, $companyName, $publicKey, $privateKey)
    {
        $this.CWApiClient.HttpBasePathUri = "/service/boards";;
    }
    
    [pscustomobject] ReadStatus([int] $boardId, $statusId)
    {
        $request = [CWApiRequestInfo]::new();
        $request.RelativePathUri = "/$boardId/statuses/$statusId";
        
        return $this.read($request);
    }
    
    [pscustomobject[]] ReadStatuses([uint32] $boardId)
    {
        return $this.ReadStatuses([uint32] $boardId, $null);
    }
    
    [pscustomobject[]] ReadStatuses([uint32] $boardId, [string] $statusConditions)
    {        
        return $this.ReadStatuses($boardId, $statusConditions, 1);
    }
    
    [pscustomobject[]] ReadStatuses([uint32] $boardId, [string] $statusConditions, [uint32] $pageNum)
    {         
        return $this.ReadStatuses($boardId, $statusConditions, 1, 0);
    }
    
    [pscustomobject[]] ReadStatuses([uint32] $boardId, [string] $statusConditions, [uint32] $pageNum, [uint32] $pageSize)
    {
        [hashtable] $queryHashtable = @{
            conditions = $statusConditions
            page       = $pageNum;
            pageSize   = $pageSize;
        }

        $relativePathUri = "/$boardId/statuses";
        return $this.read($relativePathUri, $queryHashtable);
    }
    
    [uint32] GetStatusCount([uint32] $boardId)
    {
        return $this.GetStatusCount($boardId, $null);
    }
    
    [uint32] GetStatusCount([uint32] $boardId, [string] $statusConditions)
    {
        $relativePathUri = "/$boardId/statuses/count";
        return $this.getCount($statusConditions, $relativePathUri);
    }
}