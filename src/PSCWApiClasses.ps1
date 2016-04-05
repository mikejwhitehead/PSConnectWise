enum ServiceTicketNoteTypes 
{
    Description
    Internal
    Resolution
}

# this class is not in use yet
class ModelImporter
{
    static [pscustomobject] Import ([string] $pathToJson)
    {
        [pscustomobject] $item = $null;
        
        if (Test-Path $pathToJson)
        {
            $item = Get-Content $pathToJson | Out-String | ConvertFrom-Json;
        } 
        else 
        {
            throw [System.IO.FileNotFoundException];      
        }
        
        return $item;
    }
}

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
    
    #
    # -- Constructors
    #
    
    WebRestApiRequest([hashtable] $header, [string] $url, [string] $verb, [string] $body)
    {
        $this.Url    = $url;
        $this.Header = $header;
        $this.Verb   = $verb;
        $this.Body   = $body;
        
        $this._validateWebRequestParams();
    }
    
    #
    # Methods
    #
    
    [pscustomobject] Invoke() 
    {
        if ([String]::IsNullOrWhiteSpace($this.Body))
        {
            Write-Debug "REST Request Details:  $($this | Select Url, Header, Verb | ConvertTo-Json -Depth 10 | Out-String)";
            $this.Response = Invoke-WebRequest -Uri $this.Url -Method $this.Verb -Headers $this.Header -ContentType $this.contentType;   
        }
        else
        {
            Write-Debug "REST Request Details:  $($this | Select Url, Header, Verb, Body | ConvertTo-Json -Depth 10 | Out-String)";
            $this.Response = Invoke-WebRequest -Uri $this.Url -Method $this.Verb -Headers $this.Header -Body $this.Body -ContentType $this.contentType;       
        }
    
        return $this.Response;
    }
    
    #
    #  Helper Functions
    #
    
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
    
    #
    # Static Functions
    #
    
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
    
    #
    # Static Functions - Used Internally Only
    #
    
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
    [PSObject] $Body;
    
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
    
    #
    # Constructors
    #
    
    CWApiRestClient ([string] $baseUrl, [string] $companyName, [string] $publicKey, [string] $privateKey)
    {
        $this.HttpBaseUrl     = $baseUrl;
        $this.HttpBasePathUri = "";
        $this.CWCompanyName   = $companyName;
        $this.CWApiPublicKey  = $publicKey;
        $this.CWApiPrivateKey = $privateKey;
        
        $this._validateCWApiRequestParams();
        $this.HttpHeader = $this._buildHttpHeader();
    }
    
    CWApiRestClient ([string] $baseUrl, [string] $pathUri, [string] $companyName, [string] $publicKey, [string] $privateKey)
    {
        $this.HttpBaseUrl     = $baseUrl;
        $this.HttpBasePathUri = $pathUri;
        $this.CWCompanyName   = $companyName;
        $this.CWApiPublicKey  = $publicKey;
        $this.CWApiPrivateKey = $privateKey;
        
        $this._validateCWApiRequestParams();
        $this.HttpHeader = $this._buildHttpHeader();
    }
    
    CWApiRestClient ([string] $baseUrl, [string] $pathUri, [hashtable] $header, [string] $companyName, [string] $publicKey, [string] $privateKey)
    {
        $this.HttpBaseUrl     = $baseUrl;
        $this.HttpBasePathUri = $pathUri;
        $this.CWCompanyName   = $companyName;
        $this.CWApiPublicKey  = $publicKey;
        $this.CWApiPrivateKey = $privateKey;
        
        $this._validateCWApiRequestParams();
        $this.HttpHeader = $this._buildHttpHeader();
        
        $this.transformHttpHeader($header);
    }
    
    #
    # Methods
    #
    
    [pscustomobject[]] Get ([string] $fullUrl)
    {
        [pscustomobject[]] $response = $null;
        
        $header = $this.HttpHeader;
        $verb   = "GET";
        
        [PSObject] $rawResponse = $this._request($header, $fullUrl, $verb);
        
        if ($rawResponse.StatusCode -eq 200)
        {
            $response = $rawResponse.Content | ConvertFrom-Json 
        }
        
        return $response;
    }
    
    [pscustomobject[]] Get ([CWApiRequestInfo] $request)
    {
        [pscustomobject[]] $response = $null;
        
        $header = $this.HttpHeader;
        $url    = $this.buildUrl($request.RelativePathUri, $request.QueryString);
        $verb   = $request.Verb;
        
        [PSObject] $rawResponse = $this._request($header, $url, $verb);
        
        if ($rawResponse.StatusCode -eq 200)
        {
            $response = $rawResponse.Content | ConvertFrom-Json 
        }
        
        return $response;
    }
    
    [bool] Delete ([string] $fullUrl)
    {
        $wasDeleted = $false;
        
        $header = $this.HttpHeader;
        $verb   = "DELETE";
        
        $rawResponse = $this._request($header, $fullUrl, $verb)
        
        if ($rawResponse.StatusCode -eq 204)
        {
            $wasDeleted = $true;
        }
        
        return $wasDeleted;
    }
    
    [bool] Delete ([CWApiRequestInfo] $request)
    {
        $wasDeleted = $false;
        
        $header = $this.HttpHeader;
        $url    = $this.buildUrl($request.RelativePathUri);
        $verb   = $request.Verb;
        
        $rawResponse = $this._request($header, $url, $verb);
        
        if ($rawResponse.StatusCode -eq 204)
        {
            $wasDeleted = $true;
        }
        
        return $wasDeleted; 
    }
    
    [pscustomobject] Patch ([CWApiRequestInfo] $request)
    {
        [pscustomobject] $response = $null;
        
        $header = $this.HttpHeader;
        $url    = $this.buildUrl($request.RelativePathUri);
        $verb   = $request.Verb;
        $body   = $request.Body | ConvertTo-Json -Depth 100 -Compress | Out-String
        
        $response = $this._request($header, $url, $verb, $body);
        $newItem = $response | ConvertFrom-Json 
        return $newItem;
    }
    
    [pscustomobject] Post ([CWApiRequestInfo] $request)
    {
        [pscustomobject] $response = $null;
        
        $header = $this.HttpHeader;
        $url    = $this.buildUrl($request.RelativePathUri);
        $verb   = $request.Verb;
        $body   = $request.Body | ConvertTo-Json -Depth 100 -Compress | Out-String
        
        $response = $this._request($header, $url, $verb, $body);
        $newItem = $response | ConvertFrom-Json 
        return $newItem;
    }
    
    #
    # Helper Functions
    #
    
    static [string] BuildCWQueryString ([hashtable] $queryParams)
    {
        [string[]] $validParams = @("fields", "page", "pagesize", "orderby", "conditions");
        [string] $queryString = "";
        [hashtable] $vettedQueryParams = @{};
        
        foreach ($p in $queryParams.GetEnumerator())
        {
            if ($p.Key -notin $validParams)
            {
                Write-Warning "Invalid query parameter found: $($p.Key). It was not added to the query string.";
                continue;
            }
            
            if (![String]::IsNullOrEmpty($p.Value))
            {
                $vettedQueryParams.Add($p.Key, $p.Value);   
            }    
    } 
       
        if ($vettedQueryParams.Count -gt 0)
        {
           $queryString = [WebRestApiRequest]::BuildQueryString($vettedQueryParams);
        }
        
        return $queryString;
    } 
    
    static [pscustomObject[]] BuildPatchOperations ([pscustomobject[]] $patchRequests)
    {
        return [CWApiRestClient]::BuildPatchOperations($patchRequests, $null);
    } 
    
    static [pscustomobject[]] BuildPatchOperations ([pscustomobject[]] $patchRequests, [pscustomobject] $parentObject)
    {
        # TODO: accept other HTTP PATCH verbs (ie move, copy, etc); all patch 
        [pscustomobject[]] $postInfoCollection = @()
        
        if ($patchRequests.GetType().Name.ToString() -eq "PSObject[]" -and $patchRequests.Count -eq 1)
        {
            if ($patchRequests[0].GetType().Name.ToString() -in @("PSCustomObject","PSObject"))
            {
                $patchRequests = $patchRequests[0].PSObject.Properties;
            }
        }
        
        foreach ($objDetail in $patchRequests)
        {
        
            if ($objDetail.GetType().Name.ToString() -eq "PSNoteProperty")
            {
                if ($parentObject -eq $null)
                    {
                    $patchOperation = [PSCustomObject] @{
                        op    = [string]"replace";
                        path  = [string]$null;
                        value = [string]$null;
                    }
                }
                else 
                {
                    $patchOperation = $parentObject.PSObject.Copy();
                    $patchOperation.path += "/";
                }
                
                if ($objDetail.Value.GetType().Name.ToString() -in @("PSCustomObject", "PSObject"))
                {
                    $patchOperation.path += $objDetail.Name;
                    $value = [CWApiRestClient]::BuildPatchOperations($objDetail.Value, $patchOperation);
                    $postInfoCollection += $value;    
                }
                else 
                {
                    $patchOperation.path += $objDetail.Name;
                    $patchOperation.value = $objDetail.Value.ToString();
                    $postInfoCollection += $patchOperation;
                }
            }

        }
        return $postInfoCollection
    }
    
    [string] buildUrl ([string] $relativePathUri)
    {
        return $this.buildUrl($relativePathUri, $null);
    }   
        
    [string] buildUrl ([string] $relativePathUri, [string] $queryString)
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
        
        return $url;
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
    
    #
    # Helper Functions - Used Internally Only
    #
    
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
    
    [pscustomobject] _request ($header, $url, $verb)
    {
        return $this._request($header, $url, $verb, $null);
    }
    
    [pscustomobject] _request ($header, $url, $verb, $body)
    {
        [pscustomobject] $response = $null;
        $client = [WebRestApiRequest]::new($header, $url, $verb, $body);
        
        try
        {
            $response = $client.Invoke();
        }
        catch
        {
            if ($_.Exception.Response.StatusCode.value__ -in @(400, 401, 404))
            {
                Write-Warning $_.ErrorDetails.Message;
                
            } else {
                
                throw $_;
                
            }
        }
        
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
    
    CWApiRestClientSvc ([string] $baseUrl, [string] $companyName, [string] $publicKey, [string] $privateKey)
    {
        $this.CWApiClient = [CWApiRestClient]::new($baseUrl, $companyName, $publicKey, $privateKey);
    }
    
    hidden [pscustomobject[]] QuickRead ([string] $url)
    {
        return $this.CWApiClient.Get($url);
    }
    
    hidden [pscustomobject[]] read ([string] $relativePathUri)
    {
        return $this.read($relativePathUri, $null);
    }
    
    hidden [pscustomobject[]] read ([string] $relativePathUri, [hashtable] $queryHashtable)
    {
        $MAX_PAGE_REQUEST_SIZE = 50;
        
        $request = [CWApiRequestInfo]::New();
        $request.RelativePathUri = $RelativePathUri;
        $request.Verb = "GET"; 
        
        if ($queryHashtable -ne $null)
        {
            if ($queryHashtable.Contains('pageSize') -and $queryHashtable['pageSize'] -eq 0)
            {
                $queryHashtable['pageSize'] = $MAX_PAGE_REQUEST_SIZE;
            }
            [string] $queryString = [CWApiRestClient]::BuildCWQueryString($queryHashtable);
            
            $request.QueryString = $queryString;
        }
        
        $items = $this.CWApiClient.Get($request);
        return $items;
    }
    
    hidden [bool] delete ([string] $relativePathUri)
    {
        $request = [CWApiRequestInfo]::New();
        $request.RelativePathUri = $relativePathUri;
        $request.Verb = "DELETE";
        
        $response = $this.CWApiClient.Delete($request);
        return $response;
    }
    
    hidden [pscustomobject] create ([hashtable] $newItemHashtable)
    {
        [pscustomobject] $newItem = @{};
        
        foreach ($p in $newItemHashtable.GetEnumerator())
        {
            Add-Member -parentObject $newItem -MemberType NoteProperty -Name $p.Key -Value $p.Value;
        } 
        
        return $this.create($newItem);
    }
    
    hidden [pscustomobject] create ([pscustomobject] $newItem)
    {
        return $this.create($null, $newItem);
    }
    
    hidden [pscustomobject] create ([string] $relativePathUri, [pscustomobject] $newItem)
    {
        $request = [CWApiRequestInfo]::New();
        $request.RelativePathUri = $relativePathUri;
        $request.Verb = "POST";
        $request.Body = $newItem;
        
        $response = $this.CWApiClient.Post($request);
        return $response;
    }
    
    hidden [uint32] getCount ([string] $conditions)
    {        
        return $this.getCount($conditions, "/count");
    }
    
    hidden [uint32] getCount ([string] $conditions, [string] $relativePathUri)
    {
        [hashtable] $queryParams = @{
            conditions = $conditions;
        }
        [string] $queryString = [CWApiRestClient]::BuildCWQueryString($queryParams)
        
        $response = $this.read($relativePathUri, $queryParams)[0];
        return [uint32] $response.count;
    }
}

class CwApiServiceTicketSvc : CWApiRestClientSvc
{
    CwApiServiceTicketSvc ([string] $baseUrl, [string] $companyName, [string] $publicKey, [string] $privateKey) : base($baseUrl, $companyName, $publicKey, $privateKey)
    {
        $this.CWApiClient.HttpBasePathUri = "/service/tickets";
    }
    
    [pscustomobject] ReadTicket ([int] $ticketId)
    {
        return $this.ReadTicket($ticketId, "*");
    }
    
    [pscustomobject] ReadTicket ([int] $ticketId, [string[]] $fields)
    {
        [hashtable] $queryHashtable = @{ 
            fields = ([string] [String]::Join(",", $fields)).TrimEnd(",");
        }
        
        $relativePathUri = "/$ticketID";
        
        return $this.read($relativePathUri, $queryHashtable);
    }
    
    [pscustomobject[]] ReadTickets ([string] $ticketConditions)
    {
        return $this.ReadTickets($ticketConditions, "*");
    }
    
    [pscustomobject[]] ReadTickets ([string] $ticketConditions, [string[]] $fields)
    {        
        return $this.ReadTickets($ticketConditions, $fields, 1);
    }
    
    [pscustomobject[]] ReadTickets ([string] $ticketConditions, [string[]] $fields, [uint32] $pageNum)
    {        
        return $this.ReadTickets($ticketConditions, $fields, 1, 0);
    }
    
    [pscustomobject[]] ReadTickets ([string] $ticketConditions, [string[]] $fields, [uint32] $pageNum, [uint32] $pageSize)
    {
        [hashtable] $queryParams = @{
            conditions = $ticketConditions;
            fields     = ([string] [String]::Join(",", $fields)).TrimEnd(",");
            page       = $pageNum;
            pageSize   = $pageSize;
        }
        
        return $this.read($null, $queryParams);
    }
    
    [pscustomobject] UpdateItem ([uint32] $boardId, [uint32] $contactId, [uint32] $statusId, [uint32] $priorityID)
    {
         [pscustomobject] $updatedTicket= $null;
        
        $newTicketInfo = [PSCustomObject] @{
            Board                   = [PSCustomObject] @{ ID = [uint32]$boardId;    }
            Contact                 = [PSCustomObject] @{ ID = [uint32]$contactId;  }
            Priority                = [PSCustomObject] @{ ID = [uint32]$priorityId; }
            Status                  = [PSCustomObject] @{ ID = [uint32]$statusId;   }
        }
        
        return $updatedTicket;
    }
    
    [pscustomobject] CreateTicket ([uint32] $boardId, [uint32] $companyId, [uint32] $contactId, [string] $subject, [string] $body, [string] $analysis, [uint32] $statusId, [uint32] $priorityID)
    {
        $newTicketInfo = [PSCustomObject] @{
            Board                   = [PSCustomObject] @{ ID = [uint32]$boardId;    }
            Company                 = [PSCustomObject] @{ ID = [uint32]$companyId;  }
            Contact                 = [PSCustomObject] @{ ID = [uint32]$contactId;  }
            Summary                 = [string]$subject
            InitialDescription      = [string]$body
            InitialInternalAnalysis = [string]$analysis
            Priority                = [PSCustomObject] @{ ID = [uint32]$priorityId; }
            Status                  = [PSCustomObject] @{ ID = [uint32]$statusId;   }
        }
        
        $newTicket = $this.create($newTicketInfo); 
        return $newTicket;
    }
    
    [bool] DeleteTicket ([uint32] $ticketID)
    {
        $relativePathUri = "/$ticketID";
        return $this.delete($relativePathUri);
    }
    
    [uint32] GetTicketCount ([string] $ticketConditions)
    {
        return $this.getCount($ticketConditions);
    }
    
    # static [pscustomobject] GetTicketTemplate ()
    # {
    #     ModelImporter.Import()
    # }    
    
}

class CwApiServiceBoardSvc : CWApiRestClientSvc
{
    CwApiServiceBoardSvc ([string] $baseUrl, [string] $companyName, [string] $publicKey, [string] $privateKey) : base($baseUrl, $companyName, $publicKey, $privateKey)
    {
        $this.CWApiClient.HttpBasePathUri = "/service/boards";;
    }
    
    [pscustomobject] ReadBoard ([int] $boardId)
    {
        $relativePathUri = "/$boardId";
        return $this.read($relativePathUri, $null);
    }
    
    [pscustomobject[]] ReadBoards ([string] $boardConditions)
    {        
        return $this.ReadBoards($boardConditions, 1);
    }
    
    [pscustomobject[]] ReadBoards ([string] $boardConditions, [uint32] $pageNum)
    {         
        return $this.ReadBoards($boardConditions, 1, 0);
    }
    
    [pscustomobject[]] ReadBoards ([string] $boardConditions, [uint32] $pageNum, [uint32] $pageSize)
    {
        [hashtable] $queryHashtable = @{
            conditions = $boardConditions;
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
    CwApiServiceBoardStatusSvc ([string] $baseUrl, [string] $companyName, [string] $publicKey, [string] $privateKey) : base ($baseUrl, $companyName, $publicKey, $privateKey)
    {
        $this.CWApiClient.HttpBasePathUri = "/service/boards";
    }
    
    [pscustomobject] ReadStatus([int] $boardId, $statusId)
    {
        $relativePathUri = "/$boardId/statuses/$statusId";
        return $this.read($relativePathUri);
    }
    
    [pscustomobject[]] ReadStatuses ([uint32] $boardId)
    {
        return $this.ReadStatuses([uint32] $boardId, "*");
    }
    
    [pscustomobject[]] ReadStatuses ([uint32] $boardId, [string] $fields)
    {        
        return $this.ReadStatuses($boardId, $fields, 1);
    }
    
    [pscustomobject[]] ReadStatuses ([uint32] $boardId, [string] $fields, [uint32] $pageNum)
    {         
        return $this.ReadStatuses($boardId, $fields, 1, 0);
    }
    
    [pscustomobject[]] ReadStatuses ([uint32] $boardId, [string] $fields, [uint32] $pageNum, [uint32] $pageSize)
    {
        [hashtable] $queryHashtable = @{
            fields     = $fields;
            page       = $pageNum;
            pageSize   = $pageSize;
        }

        $relativePathUri = "/$boardId/statuses";
        return $this.read($relativePathUri, $queryHashtable);
    }
    
    [uint32] GetStatusCount ([uint32] $boardId)
    {
        return $this.GetStatusCount($boardId, $null);
    }
    
    [uint32] GetStatusCount ([uint32] $boardId, [string] $statusConditions)
    {
        $relativePathUri = "/$boardId/statuses/count";
        return $this.getCount($statusConditions, $relativePathUri);
    }
}

class CwApiServiceBoardTypeSvc : CWApiRestClientSvc
{
    CwApiServiceBoardTypeSvc ([string] $baseUrl, [string] $companyName, [string] $publicKey, [string] $privateKey) : base ($baseUrl, $companyName, $publicKey, $privateKey)
    {
        $this.CWApiClient.HttpBasePathUri = "/service/boards";
    }
    
    [pscustomobject] ReadType([int] $boardId, $typeId)
    {
        $relativePathUri = "/$boardId/types/$typeId";
        return $this.read($relativePathUri);
    }
    
    [pscustomobject[]] ReadTypes ([uint32] $boardId)
    {
        return $this.ReadTypes([uint32] $boardId, "*");
    }
    
    [pscustomobject[]] ReadTypes ([uint32] $boardId, [string] $fields)
    {        
        return $this.ReadTypes($boardId, $fields, 1);
    }
    
    [pscustomobject[]] ReadTypes ([uint32] $boardId, [string] $fields, [uint32] $pageNum)
    {         
        return $this.ReadTypes($boardId, $fields, 1, 0);
    }
    
    [pscustomobject[]] ReadTypes ([uint32] $boardId, [string] $fields, [uint32] $pageNum, [uint32] $pageSize)
    {
        [hashtable] $queryHashtable = @{
            fields     = $fields;
            page       = $pageNum;
            pageSize   = $pageSize;
        }

        $relativePathUri = "/$boardId/types";
        return $this.read($relativePathUri, $queryHashtable);
    }
    
    [uint32] GetTypeCount ([uint32] $boardId)
    {
        return $this.GetTypeCount($boardId, $null);
    }
    
    [uint32] GetTypeCount ([uint32] $boardId, [string] $typeConditions)
    {
        $relativePathUri = "/$boardId/types/count";
        return $this.getCount($typeConditions, $relativePathUri);
    }
}

class CwApiServicePrioritySvc : CWApiRestClientSvc
{

    CwApiServicePrioritySvc ([string] $baseUrl, [string] $companyName, [string] $publicKey, [string] $privateKey) : base($baseUrl, $companyName, $publicKey, $privateKey)
    {
        $this.CWApiClient.HttpBasePathUri = "/service/priorities";
    }
    
    [pscustomobject] ReadPriority([uint32] $priorityId)
    {
        $relativePathUri = "/$priorityId";
        return $this.read($relativePathUri, $null);
    }
    
    [pscustomobject[]] ReadPriorities ([string] $priorityConditions)
    {        
        return $this.ReadPriorities($priorityConditions, 1);
    }
    
    [pscustomobject[]] ReadPriorities ([string] $priorityConditions, [uint32] $pageNum)
    {         
        return $this.ReadPriorities($priorityConditions, 1, 0);
    }
    
    [pscustomobject[]] ReadPriorities ([string] $priorityConditions, [uint32] $pageNum, [uint32] $pageSize)
    {
        [hashtable] $queryHashtable = @{
            conditions = $priorityConditions;
            page       = $pageNum;
            pageSize   = $pageSize;
        }
        
        return $this.read($null, $queryHashtable);
    }
    
    [uint32] GetPriorityCount([string] $priorityConditions)
    {
        return $this.getCount($priorityConditions);
    }
    
}

class CwApiServiceTicketNoteSvc : CWApiRestClientSvc
{
    CwApiServiceTicketNoteSvc ([string] $baseUrl, [string] $companyName, [string] $publicKey, [string] $privateKey) : base($baseUrl, $companyName, $publicKey, $privateKey)
    {
        $this.CWApiClient.HttpBasePathUri = "/service/tickets";
    }
    
    [pscustomobject] ReadNote ([uint32] $ticketId, [int] $timeEntryId)
    {
        $relativePathUri = "/$ticketId/notes/$timeEntryId";
        return $this.read($relativePathUri, $null);
    }
    
    [pscustomobject[]] ReadNotes ([uint32] $ticketId)
    {
        return $this.ReadTimeEntries($ticketId, 1, 0)
    }
    
    [pscustomobject[]] ReadNotes ([uint32] $ticketId, [uint32] $pageNum, [uint32] $pageSize)
    {
        [hashtable] $queryHashtable = @{
            page       = $pageNum;
            pageSize   = $pageSize;
        }
        
        $relativePathUri = "/$ticketId/notes";
        return $this.read($relativePathUri, $queryHashtable);
    }
    
    [pscustomobject] CreateNote ([uint32] $ticketId, [string] $message, [ServiceTicketNoteTypes[]] $addTo)
    {
        $newTicketNote = [PSCustomObject] @{
            Text                  = [string]$message
            DetailDescriptionFlag = [ServiceTicketNoteTypes]::Description -in $addTo
            InternalAnalysisFlag  = [ServiceTicketNoteTypes]::Internal -in $addTo
            ResolutionFlag        = [ServiceTicketNoteTypes]::Resolution -in $addTo
        }
        
        $relativePathUri = "/$ticketId/notes";
        $newTicketNote = $this.create($relativePathUri, $newTicketNote); 
        return $newTicketNote;
    }
    
    [uint32] GetNoteCount ([uint32] $ticketId)
    {
        $relativePathUri = "/$ticketId/notes/count";
        return $this.GetCount($null, $relativePathUri);
    }
}
