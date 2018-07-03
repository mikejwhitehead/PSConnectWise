enum CWServiceTicketNoteTypes
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
            Write-Debug "REST Request Details:  $($this | Select-Object Url, Header, Verb | ConvertTo-Json -Depth 10 | Out-String)";
            $this.Response = Invoke-WebRequest -Uri $this.Url -Method $this.Verb -Headers $this.Header -ContentType $this.contentType -UseBasicParsing;
        }
        else
        {
            Write-Debug "REST Request Details:  $($this | Select-Object Url, Header, Verb, Body | ConvertTo-Json -Depth 10 | Out-String)";
            $this.Response = Invoke-WebRequest -Uri $this.Url -Method $this.Verb -Headers $this.Header -Body $this.Body -ContentType $this.contentType -UseBasicParsing;
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
            if ($null -eq $p.Value)
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

class CWApiRestSession
{
    [string] $Domain;
    [string] $CompanyName;
    [string] $PublicKey;
    [string] $PrivateKey;
    [string] $CodeBase;
    [string] $BaseUrl;
    [hashtable] $Header;
    [string] $ApiVersion = "3.0";
    [bool] $OverrideSSL = $false;

    CWApiRestSession ([string] $domain, [string] $companyName, [string] $publicKey, [string] $privateKey)
    {
        $this.Domain      = $domain;
        $this.CompanyName = $companyName;
        $this.PublicKey   = $publicKey;
        $this.PrivateKey  = $privateKey;

        if (!$this._setCodeBase())
        {
           throw
        }

        $this._buildBaseUri();
        $this._buildHttpHeader();
    }

    CWApiRestSession ([string] $domain, [string] $companyName, [string] $publicKey, [string] $privateKey, [bool] $overrideSSL)
    {
        $this.Domain      = $domain;
        $this.CompanyName = $companyName;
        $this.PublicKey   = $publicKey;
        $this.PrivateKey  = $privateKey;
        $this.OverrideSSL = $overrideSSL;

        if (!$this._setCodeBase())
        {
           throw
        }

        $this._buildBaseUri();
        $this._buildHttpHeader();
    }

    hidden [boolean] _setCodeBase ()
    {
        $companyInfoRaw = Invoke-WebRequest -Uri $([String]::Format("https://{0}/login/companyinfo/{1}", $this.Domain, $this.CompanyName)) -UseBasicParsing;
        $companyInfo = ConvertFrom-Json -InputObject $companyInfoRaw;

        $this.CodeBase = $companyInfo.Codebase;

        return $true;
    }

    hidden [void] _buildBaseUri ()
    {
        $this.BaseUrl = [String]::Format("https://{0}/{1}apis/{2}", $this.Domain, $this.CodeBase, $this.apiVersion);
    }

    hidden [void] _buildHttpHeader ()
    {
        $this.Header = [hashtable] @{
            "Authorization"    = $this._createCWAuthenticationString();
            "Accept"           = "application/vnd.connectwise.com+json;";
            "Type"             = "application/json";
        }

        if ($this.OverrideSSL)
        {
            $this.Header.Add("x-cw-overridessl", "True");
        }
    }

    hidden [string] _createCWAuthenticationString ()
    {
        [string] $encodedString = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}+{1}:{2}" -f $this.CompanyName, $this.PublicKey, $this.PrivateKey)));
        return [String]::Format("Basic {0}", $encodedString);
    }

}

class CWApiRestClient
{
    # public properties
    [string] $RelativeBaseEndpointUri = "";
    [CWApiRestSession] $CWConnectionInfo;

    #
    # Constructors
    CWApiRestClient ([CWApiRestSession] $session)
    {
        $this.CWConnectionInfo = $session
    }

    #
    # Methods
    #

    [pscustomobject[]] Get ([string] $fullUrl)
    {
        [pscustomobject[]] $response = $null;

        $header = $this.CWConnectionInfo.Header;
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

        $header = $this.CWConnectionInfo.Header;
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

        $header = $this.CWConnectionInfo.Header;
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

        $header = $this.CWConnectionInfo.Header;
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

        $header = $this.CWConnectionInfo.Header;
        $url    = $this.buildUrl($request.RelativePathUri);
        $verb   = $request.Verb;
        $body   = ConvertTo-Json -InputObject @($request.Body) -Depth 100 -Compress | Out-String

        $response = $this._request($header, $url, $verb, $body);
        $newItem = $response | ConvertFrom-Json
        return $newItem;
    }

    [pscustomobject] Post ([CWApiRequestInfo] $request)
    {
        [pscustomobject] $response = $null;

        $header = $this.CWConnectionInfo.Header;
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

    static [pscustomobject[]] BuildPatchOperations ([pscustomobject] $patchRequests)
    {
        return [CWApiRestClient]::BuildPatchOperations($patchRequests, $null);
    }

    static [pscustomobject[]] BuildPatchOperations ([pscustomobject] $patchRequests, [pscustomobject] $parentObject)
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
                if ($null -eq $parentObject)
                    {
                    $patchOperation = [PSCustomObject] @{
                        op    = [string]"replace";
                        path  = [string]"/";
                        value = [string]$null;
                    }
                }
                else
                {
                    $patchOperation = $parentObject.PSObject.Copy();
                    $patchOperation.path += "/";
                }

                if ($null -ne $objDetail.Value -and $objDetail.Value.GetType().Name.ToString() -in @("PSCustomObject", "PSObject"))
                {
                    $name = $objDetail.Name.SubString(0,1).ToLower();
                    $name += $objDetail.Name.Substring(1, $objDetail.Name.Length - 1);
                    $patchOperation.path += $name;
                    $value = [CWApiRestClient]::BuildPatchOperations([psobject[]] $objDetail.Value, $patchOperation);
                    $postInfoCollection += $value;
                }
                else
                {
                    # do not create an operation obj if the property value is null or numeric value is 0
                    if ($null -eq $objDetail.Value -or ($objDetail.Value.GetType().IsValueType -and $objDetail.Value -eq 0))
                    {
                        continue;
                    }

                    $name = $objDetail.Name.SubString(0,1).ToLower();
                    $name += $objDetail.Name.Substring(1, $objDetail.Name.Length - 1);
                    $patchOperation.path += $name;
                    $patchOperation.value = $objDetail.Value.ToString();
                    $postInfoCollection += $patchOperation;
                }
            }

        }
        return [pscustomobject[]] $postInfoCollection
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

        $url = [String]::Format("{0}{1}{2}{3}", $this.CWConnectionInfo.BaseUrl, $this.RelativeBaseEndpointUri, $relativePathUri, $queryString);

        return $url;
    }

    #
    # Helper Functions - Used Internally Only
    #


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
                if ($null -ne $_.ErrorDetails.Message)
                {
                    Write-Error $_.ErrorDetails.Message;
                }
                elseif ($null -ne $_.Exception.Message)
                {
                    Write-Error $_.Exception.Message;
                }
                else
                {
                    throw $_;
                }
            }
            else
            {
                throw $_;
            }
        }

        return $response;
    }
}

class CWApiRestClientSvc
{
    hidden [CWApiRestClient] $CWApiClient;

    CWApiRestClientSvc ([CWApiRestSession] $session)
    {
        $this.CWApiClient = [CWApiRestClient]::New($session)
    }

    [pscustomobject[]] QuickRead ([string] $url)
    {
        return $this.CWApiClient.Get($url);
    }

    [pscustomobject[]] ServerInfo ()
    {
        $request = [CWApiRequestInfo]::New();
        $request.RelativePathUri = "/system/info";
        $request.Verb = "GET";

        $info = $null;

        try
        {
            $info = $this.CWApiClient.Get($request);
        }
        catch
        {
            # lazy error handling / do nothing
        }

        return $info;
    }

    [boolean] TestConnection ()
    {
        $info = $this.ServerInfo();
        return $null -ne $info -and $null -ne $info.version;
    }

    [psobject[]] ReadRequest ([string] $relativePathUri)
    {
        return $this.ReadRequest($relativePathUri, $null);
    }

    [psobject[]] ReadRequest ([string] $relativePathUri, [hashtable] $queryHashtable)
    {
        $MAX_PAGE_REQUEST_SIZE = 50;

        $request = [CWApiRequestInfo]::New();
        $request.RelativePathUri = $relativePathUri;
        $request.Verb = "GET";

        if ($null -ne $queryHashtable)
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

    [bool] DeleteRequest ([string] $relativePathUri)
    {
        $request = [CWApiRequestInfo]::New();
        $request.RelativePathUri = $relativePathUri;
        $request.Verb = "Delete";

        $response = $this.CWApiClient.Delete($request);
        return $response;
    }

    [pscustomobject] CreateRequest ([hashtable] $newItemHashtable)
    {
        [pscustomobject] $newItem = @{};

        foreach ($p in $newItemHashtable.GetEnumerator())
        {
            Add-Member -parentObject $newItem -MemberType NoteProperty -Name $p.Key -Value $p.Value;
        }

        return $this.CreateRequest($newItem);
    }

    [pscustomobject] CreateRequest ([pscustomobject] $newItem)
    {
        return $this.CreateRequest($null, $newItem);
    }

    [pscustomobject] CreateRequest ([string] $relativePathUri, [pscustomobject] $newItem)
    {
        $request = [CWApiRequestInfo]::New();
        $request.RelativePathUri = $relativePathUri;
        $request.Verb = "POST";
        $request.Body = $newItem;

        $response = $this.CWApiClient.Post($request);
        return $response;
    }

    [pscustomobject] UpdateRequest ([string] $relativePathUri, [pscustomobject[]] $itemUpdates)
    {
        $request = [CWApiRequestInfo]::New();
        $request.RelativePathUri = $relativePathUri;
        $request.Verb = "PATCH";
        $request.Body = [CWApiRestClient]::BuildPatchOperations($itemUpdates);

        $response = $this.CWApiClient.Patch($request);
        return $response;
    }

    [uint32] GetCount ([string] $conditions)
    {
        return $this.GetCount($conditions, "/count");
    }

    [uint32] GetCount ([string] $conditions, [string] $relativePathUri)
    {
        [hashtable] $queryParams = @{
            conditions = $conditions;
        }
        [string] $queryString = [CWApiRestClient]::BuildCWQueryString($queryParams)

        $response = $this.ReadRequest($relativePathUri, $queryParams)[0];
        return [uint32] $response.count;
    }
}

class CwApiServiceTicketSvc : CWApiRestClientSvc
{

    CwApiServiceTicketSvc ([CWApiRestSession] $session) : base($session)
    {
        $this.CWApiClient.RelativeBaseEndpointUri = "/service/tickets";
    }

    [psobject] ReadTicket ([uint32] $ticketId)
    {
        return $this.ReadTicket($ticketId, "*");
    }

    [psobject] ReadTicket ([uint32] $ticketId, [string[]] $fields)
    {
        [hashtable] $queryHashtable = @{}

        if ($null -ne $fields)
        {
            $queryHashtable["fields"] = ([string] [String]::Join(",", $fields)).TrimEnd(",");
        }

        $relativePathUri = "/$ticketID";

        return $this.ReadRequest($relativePathUri, $queryHashtable);
    }

    [psobject[]] ReadTickets ([string] $ticketConditions)
    {
        return $this.ReadTickets($ticketConditions, "*");
    }

    [psobject[]] ReadTickets ([string] $ticketConditions, [string[]] $fields)
    {
        return $this.ReadTickets($ticketConditions, $fields, 1);
    }

    [psobject[]] ReadTickets ([string] $ticketConditions, [string[]] $fields, [uint32] $pageNum)
    {
        return $this.ReadTickets($ticketConditions, $fields, $pageNum, 0);
    }

    [psobject[]] ReadTickets ([string] $ticketConditions, [string[]] $fields, [uint32] $pageNum, [uint32] $pageSize)
    {
        return $this.ReadTickets($ticketConditions, $fields, $null, $pageNum, $pageSize);
    }

    [psobject[]] ReadTickets ([string] $ticketConditions, [string[]] $fields, [string] $orderBy, [uint32] $pageNum, [uint32] $pageSize)
    {
        [hashtable] $queryParams = @{
            conditions = $ticketConditions;
            page       = $pageNum;
            pageSize   = $pageSize;
            orderBy    = $orderBy;
        }

        if ($null -ne $fields)
        {
            $queryParams.Add("fields", ([string] [String]::Join(",", $fields)).TrimEnd(","));
        }

        return $this.ReadRequest($null, $queryParams);
    }

    [pscustomobject] UpdateTicket ([uint32] $ticketId, [uint32] $boardId, [uint32] $contactId, [uint32] $statusId, [uint32] $priorityID)
    {
        return $this.UpdateTicket($ticketId, $boardId, $contactId, $statusId, $priorityID, $null);
    }

    [pscustomobject] UpdateTicket ([uint32] $ticketId, [uint32] $boardId, [uint32] $contactId, [uint32] $statusId, [uint32] $priorityID, $summary)
    {
        [pscustomobject] $UpdatedTicket= $null;

        if ([String]::IsNullOrEmpty($summary))
        {
            $summary = $null
        }

        $newTicketInfo = [PSCustomObject] @{
            Summary  = $summary;
            Board    = [PSCustomObject] @{ Id = [uint32]$boardId;    }
            Contact  = [PSCustomObject] @{ Id = [uint32]$contactId;  }
            Priority = [PSCustomObject] @{ Id = [uint32]$priorityId; }
            Status   = [PSCustomObject] @{ Id = [uint32]$statusId;   }
        }

        $relativePathUri = "/$ticketID";
        $UpdatedTicket = $this.UpdateRequest($relativePathUri, $newTicketInfo)

        return $UpdatedTicket;
    }

    [pscustomobject] CreateTicket ([uint32] $boardId, [uint32] $companyId, [uint32] $contactId, [string] $subject, [string] $body, [string] $analysis, [uint32] $statusId, [string]$severity, [string]$impact, [uint32] $sourceId, [uint32] $priorityID, [uint32]$typeId, [uint32]$subTypeId, [uint32]$itemId)
    {
        $newTicketInfo = [PSCustomObject] @{
            Board                   = [PSCustomObject] @{ Id = [uint32]$boardId;    }
            Company                 = [PSCustomObject] @{ Id = [uint32]$companyId;  }
            Contact                 = [PSCustomObject] @{ Id = [uint32]$contactId;  }
            Summary                 = [string]$subject
            InitialDescription      = [string]$body
            InitialInternalAnalysis = [string]$analysis
            Priority                = [PSCustomObject] @{ Id = [uint32]$priorityId; }
            Severity                = [string]$severity
            Impact                  = [string]$impact
            Status                  = [PSCustomObject] @{ Id = [uint32]$statusId;   }
            Source                  = [PSCustomObject] @{ Id = [uint32]$sourceId;   }
            Type                    = [PSCustomObject] @{ Id = [uint32]$typeId;   }
            SubType                 = [PSCustomObject] @{ Id = [uint32]$subTypeId;   }
            Item                    = [PSCustomObject] @{ Id = [uint32]$itemId;   }
        }

        $newTicket = $this.CreateRequest($newTicketInfo);
        return $newTicket;
    }

    [bool] DeleteTicket ([uint32] $ticketID)
    {
        $relativePathUri = "/$ticketID";
        return $this.DeleteRequest($relativePathUri);
    }

    [uint32] GetTicketCount ([string] $ticketConditions)
    {
        return $this.GetCount($ticketConditions);
    }
}

class CwApiServiceTicketExtendedSvc : CwApiServiceTicketSvc
{
    CwApiServiceTicketExtendedSvc ([CWApiRestSession] $session) : base($session)
    {
    }

    [psobject[]] ReadTicketTimeEntries ([uint32] $ticketId)
    {
        return $this.ReadTicketTimeEntries($ticketID)
    }

    [psobject[]] ReadTicketTimeEntries ([uint32] $ticketId, $pageNum, $pageSize)
    {
        [hashtable] $queryParams = @{
            page       = $pageNum;
            pageSize   = $pageSize;
        }

        $relativePathUri = "/$ticketID/timeentries";

        return $this.ReadRequest($relativePathUri, $queryParams);
    }


    [uint32] ReadTicketTimeEntryCount ([uint32] $ticketId)
    {
        $relativePathUri = "/$ticketID/timeentries/count";

        $timeEntryCount = $this.ReadRequest($relativePathUri, $null);

        return $timeEntryCount[0].count;
    }
}

class CwApiServiceBoardSvc : CWApiRestClientSvc
{
    CwApiServiceBoardSvc ([CWApiRestSession] $session) : base($session)
    {
        $this.CWApiClient.RelativeBaseEndpointUri = "/service/boards";
    }

    [psobject] ReadBoard ([uint32] $boardId)
    {
        $relativePathUri = "/$boardId";
        return $this.ReadRequest($relativePathUri, $null);
    }

    [psobject[]] ReadBoards ([string] $boardConditions)
    {
        return $this.ReadBoards($boardConditions, 1);
    }

    [psobject[]] ReadBoards ([string] $boardConditions, [uint32] $pageNum)
    {
        return $this.ReadBoards($boardConditions, $pageNum, 0);
    }

    [psobject[]] ReadBoards ([string] $boardConditions, [uint32] $pageNum, [uint32] $pageSize)
    {
        return $this.ReadBoards($boardConditions, $null, $pageNum, $pageSize);
    }

    [psobject[]] ReadBoards ([string] $boardConditions, [string] $orderBy, [uint32] $pageNum, [uint32] $pageSize)
    {
        [hashtable] $queryHashtable = @{
            conditions = $boardConditions;
            page       = $pageNum;
            pageSize   = $pageSize;
            orderBy    = $orderBy;
        }

        return $this.ReadRequest($null, $queryHashtable);
    }

    [uint32] GetBoardCount([string] $boardConditions)
    {
        return $this.GetCount($boardConditions);
    }

}

class CwApiServiceBoardStatusSvc : CWApiRestClientSvc
{
    CwApiServiceBoardStatusSvc ([CWApiRestSession] $session) : base($session)
    {
        $this.CWApiClient.RelativeBaseEndpointUri = "/service/boards";
    }

    [psobject] ReadStatus([int] $boardId, $statusId)
    {
        $relativePathUri = "/$boardId/statuses/$statusId";
        return $this.ReadRequest($relativePathUri);
    }

    [psobject[]] ReadStatuses ([uint32] $boardId)
    {
        return $this.ReadStatuses([uint32] $boardId, "*");
    }

    [psobject[]] ReadStatuses ([uint32] $boardId, [string] $fields)
    {
        return $this.ReadStatuses($boardId, $fields, 1);
    }

    [psobject[]] ReadStatuses ([uint32] $boardId, [string] $fields, [uint32] $pageNum)
    {
        return $this.ReadStatuses($boardId, $fields, $pageNum, 0);
    }

    [psobject[]] ReadStatuses ([uint32] $boardId, [string] $fields, [uint32] $pageNum, [uint32] $pageSize)
    {
        return $this.ReadStatuses($boardId, $fields, $null, $pageNum, $pageSize);
    }

    [psobject[]] ReadStatuses ([uint32] $boardId, [string] $fields, [string] $orderBy, [uint32] $pageNum, [uint32] $pageSize)
    {
        [hashtable] $queryHashtable = @{
            fields     = $fields;
            page       = $pageNum;
            pageSize   = $pageSize;
            orderBy    = $orderBy;
        }

        $relativePathUri = "/$boardId/statuses";
        return $this.ReadRequest($relativePathUri, $queryHashtable);
    }

    [uint32] GetStatusCount ([uint32] $boardId)
    {
        return $this.GetStatusCount($boardId, $null);
    }

    [uint32] GetStatusCount ([uint32] $boardId, [string] $statusConditions)
    {
        $relativePathUri = "/$boardId/statuses/count";
        return $this.GetCount($statusConditions, $relativePathUri);
    }
}

class CwApiServiceBoardTypeSvc : CWApiRestClientSvc
{
    CwApiServiceBoardTypeSvc ([CWApiRestSession] $session) : base($session)
    {
        $this.CWApiClient.RelativeBaseEndpointUri = "/service/boards";
    }

    [psobject] ReadType([uint32] $boardId, $typeId)
    {
        $relativePathUri = "/$boardId/types/$typeId";
        return $this.ReadRequest($relativePathUri);
    }

    [psobject[]] ReadTypes ([uint32] $boardId)
    {
        return $this.ReadTypes([uint32] $boardId, "*");
    }

    [psobject[]] ReadTypes ([uint32] $boardId, [string] $fields)
    {
        return $this.ReadTypes($boardId, $fields, 1);
    }

    [psobject[]] ReadTypes ([uint32] $boardId, [string] $fields, [uint32] $pageNum)
    {
        return $this.ReadTypes($boardId, $fields, $pageNum, 0);
    }

    [psobject[]] ReadTypes ([uint32] $boardId, [string] $fields, [uint32] $pageNum, [uint32] $pageSize)
    {
        return $this.ReadTypes($boardId, $fields, $null, $pageNum, $pageSize);
    }

    [psobject[]] ReadTypes ([uint32] $boardId, [string] $fields, [string] $orderBy, [uint32] $pageNum, [uint32] $pageSize)
    {
        [hashtable] $queryHashtable = @{
            fields     = $fields;
            page       = $pageNum;
            pageSize   = $pageSize;
            orderBy    = $orderBy;
        }

        $relativePathUri = "/$boardId/types";
        return $this.ReadRequest($relativePathUri, $queryHashtable);
    }

    [uint32] GetTypeCount ([uint32] $boardId)
    {
        return $this.GetTypeCount($boardId, $null);
    }

    [uint32] GetTypeCount ([uint32] $boardId, [string] $typeConditions)
    {
        $relativePathUri = "/$boardId/types/count";
        return $this.GetCount($typeConditions, $relativePathUri);
    }
}

class CwApiServiceBoardSubtypeSvc : CWApiRestClientSvc
{
    CwApiServiceBoardSubtypeSvc ([CWApiRestSession] $session) : base($session)
    {
        $this.CWApiClient.RelativeBaseEndpointUri = "/service/boards";
    }

    [psobject] ReadType([int] $boardId, $typeId)
    {
        $relativePathUri = "/$boardId/subtypes/$typeId";
        return $this.ReadRequest($relativePathUri);
    }

    [psobject[]] ReadTypes ([uint32] $boardId)
    {
        return $this.ReadTypes([uint32] $boardId, "*");
    }

    [psobject[]] ReadTypes ([uint32] $boardId, [string] $fields)
    {
        return $this.ReadTypes($boardId, $fields, 1);
    }

    [psobject[]] ReadTypes ([uint32] $boardId, [string] $fields, [uint32] $pageNum)
    {
        return $this.ReadTypes($boardId, $fields, $pageNum, 0);
    }

    [psobject[]] ReadTypes ([uint32] $boardId, [string] $fields, [uint32] $pageNum, [uint32] $pageSize)
    {
        return $this.ReadTypes($boardId, $fields, $null, $pageNum, $pageSize);
    }

    [psobject[]] ReadTypes ([uint32] $boardId, [string] $fields, [string] $orderBy, [uint32] $pageNum, [uint32] $pageSize)
    {
        [hashtable] $queryHashtable = @{
            fields     = $fields;
            page       = $pageNum;
            pageSize   = $pageSize;
            orderBy    = $orderBy;
        }

        $relativePathUri = "/$boardId/subtypes";
        return $this.ReadRequest($relativePathUri, $queryHashtable);
    }

    [uint32] GetTypeCount ([uint32] $boardId)
    {
        return $this.GetTypeCount($boardId, $null);
    }

    [uint32] GetTypeCount ([uint32] $boardId, [string] $typeConditions)
    {
        $relativePathUri = "/$boardId/subtypes/count";
        return $this.GetCount($typeConditions, $relativePathUri);
    }
}

class CwApiServicePrioritySvc : CWApiRestClientSvc
{
    CwApiServicePrioritySvc ([CWApiRestSession] $session) : base($session)
    {
        $this.CWApiClient.RelativeBaseEndpointUri = "/service/priorities";
    }

    [psobject] ReadPriority([uint32] $priorityId)
    {
        $relativePathUri = "/$priorityId";
        return $this.ReadRequest($relativePathUri, $null);
    }

    [psobject[]] ReadPriorities ([string] $priorityConditions)
    {
        return $this.ReadPriorities($priorityConditions, 1);
    }

    [psobject[]] ReadPriorities ([string] $priorityConditions, [uint32] $pageNum)
    {
        return $this.ReadPriorities($priorityConditions, $pageNum, 0);
    }

    [psobject[]] ReadPriorities ([string] $priorityConditions, [uint32] $pageNum, [uint32] $pageSize)
    {
        return $this.ReadPriorities($priorityConditions, $null, $pageNum, $pageSize);
    }

    [psobject[]] ReadPriorities ([string] $priorityConditions, [string] $orderBy, [uint32] $pageNum, [uint32] $pageSize)
    {
        [hashtable] $queryHashtable = @{
            conditions = $priorityConditions;
            page       = $pageNum;
            pageSize   = $pageSize;
            orderBy    = $orderBy;
        }

        return $this.ReadRequest($null, $queryHashtable);
    }

    [uint32] GetPriorityCount([string] $priorityConditions)
    {
        return $this.GetCount($priorityConditions);
    }

}

class CwApiServiceSourceSvc : CWApiRestClientSvc
{
    CwApiServiceSourceSvc ([CWApiRestSession] $session) : base($session)
    {
        $this.CWApiClient.RelativeBaseEndpointUri = "/service/sources";
    }

    [psobject] ReadSource([uint32] $sourceId)
    {
        $relativePathUri = "/$sourceId";
        return $this.ReadRequest($relativePathUri, $null);
    }

    [psobject[]] ReadSources ([string] $sourceConditions)
    {
        return $this.ReadSources($sourceConditions, 1);
    }

    [psobject[]] ReadSources ([string] $sourceConditions, [uint32] $pageNum)
    {
        return $this.ReadSources($sourceConditions, $pageNum, 0);
    }

    [psobject[]] ReadSources ([string] $sourceConditions, [uint32] $pageNum, [uint32] $pageSize)
    {
        return $this.ReadSources($sourceConditions, $null, $pageNum, $pageSize);
    }

    [psobject[]] ReadSources ([string] $sourceConditions, [string] $orderBy, [uint32] $pageNum, [uint32] $pageSize)
    {
        [hashtable] $queryHashtable = @{
            conditions = $sourceConditions;
            page       = $pageNum;
            pageSize   = $pageSize;
            orderBy    = $orderBy;
        }

        return $this.ReadRequest($null, $queryHashtable);
    }

    [uint32] GetPriorityCount([string] $priorityConditions)
    {
        return $this.GetCount($priorityConditions);
    }

}


class CwApiServiceTicketNoteSvc : CWApiRestClientSvc
{
    CwApiServiceTicketNoteSvc ([CWApiRestSession] $session) : base($session)
    {
        $this.CWApiClient.RelativeBaseEndpointUri = "/service/tickets";
    }

    [psobject] ReadNote ([uint32] $ticketId, [uint32] $timeEntryId)
    {
        $relativePathUri = "/$ticketId/notes/$timeEntryId";
        return $this.ReadRequest($relativePathUri, $null);
    }

    [psobject[]] ReadNotes ([uint32] $ticketId)
    {
        return $this.ReadNotes($ticketId, 1, 0)
    }

    [psobject[]] ReadNotes ([uint32] $ticketId, [uint32] $pageNum, [uint32] $pageSize)
    {
        return $this.ReadNotes($ticketId, $null, $pageNum, $pageSize)
    }

    [psobject[]] ReadNotes ([uint32] $ticketId, [string] $orderBy, [uint32] $pageNum, [uint32] $pageSize)
    {
        [hashtable] $queryHashtable = @{
            page       = $pageNum;
            pageSize   = $pageSize;
            orderBy    = $orderBy;
        }

        $relativePathUri = "/$ticketId/notes";
        return $this.ReadRequest($relativePathUri, $queryHashtable);
    }

    [pscustomobject] CreateNote ([uint32] $ticketId, [string] $message, [CWServiceTicketNoteTypes[]] $addTo)
    {
        $newTicketNote = [PSCustomObject] @{
            Text                  = [string]$message
            DetailDescriptionFlag = [CWServiceTicketNoteTypes]::Description -in $addTo
            InternalAnalysisFlag  = [CWServiceTicketNoteTypes]::Internal -in $addTo
            ResolutionFlag        = [CWServiceTicketNoteTypes]::Resolution -in $addTo
        }

        $relativePathUri = "/$ticketId/notes";
        $newTicketNote = $this.CreateRequest($relativePathUri, $newTicketNote);
        return $newTicketNote;
    }

    [uint32] GetNoteCount ([uint32] $ticketId)
    {
        $relativePathUri = "/$ticketId/notes/count";
        return $this.GetCount($null, $relativePathUri);
    }
}

class CwApiCompanySvc : CWApiRestClientSvc
{
    CwApiCompanySvc ([CWApiRestSession] $session) : base($session)
    {
        $this.CWApiClient.RelativeBaseEndpointUri = "/company/companies";
    }

    [psobject] ReadCompany([uint32] $companyId)
    {
        return $this.ReadCompany($companyId, "*");
    }

    [psobject] ReadCompany([uint32] $companyId, [string[]] $fields)
    {
        [hashtable] $queryHashtable = @{}

        if ($null -ne $fields)
        {
            $queryHashtable["fields"] = ([string] [String]::Join(",", $fields)).TrimEnd(",");
        }

        $relativePathUri = "/$companyId";

        $company = $this.ReadRequest($relativePathUri, $queryHashtable);

        return $company
    }

    [psobject[]] ReadCompanies ([string] $companyConditions)
    {
        return $this.ReadCompanies($companyConditions, "*");
    }

    [psobject[]] ReadCompanies ([string] $companyConditions, [string[]] $fields)
    {
        return $this.ReadCompanies($companyConditions, $fields, 1);
    }

    [psobject[]] ReadCompanies ([string] $companyConditions, [string[]] $fields, [uint32] $pageNum)
    {
        return $this.ReadCompanies($companyConditions, $fields, $pageNum, 0);
    }

    [psobject[]] ReadCompanies ([string] $companyConditions, [string[]] $fields, [uint32] $pageNum, [uint32] $pageSize)
    {
        return $this.ReadCompanies($companyConditions, $fields, $null, $pageNum, 0);
    }

    [psobject[]] ReadCompanies ([string] $companyConditions, [string[]] $fields, [string]$orderBy, [uint32] $pageNum, [uint32] $pageSize)
    {
        [hashtable] $queryHashtable = @{
            conditions = $companyConditions;
            page       = $pageNum;
            pageSize   = $pageSize;
            orderBy    = $orderBy;
        }

        if ($null -ne $fields)
        {
            $queryHashtable.Add("fields", ([string] [String]::Join(",", $fields)).TrimEnd(","));
        }

        return $this.ReadRequest($null, $queryHashtable);
    }

    [uint32] GetCompanyCount([string] $companyConditions)
    {
        return $this.GetCount($companyConditions);
    }

}

class CwApiCompanyContactSvc : CWApiRestClientSvc
{
    CwApiCompanyContactSvc ([CWApiRestSession] $session) : base($session)
    {
        $this.CWApiClient.RelativeBaseEndpointUri = "/company/contacts";
    }

    [psobject] ReadContact ([uint32] $contactId)
    {
        return $this.ReadContact($contactId, $null)
    }

    [psobject] ReadContact ([uint32] $contactId, $fields)
    {
        [hashtable] $queryHashtable = @{
            fields = $null;
        }

        if ($null -ne $fields)
        {
            $queryHashtable.fields = ([string] [String]::Join(",", $fields)).TrimEnd(",");
        }

        $relativePathUri = "/$contactId";

        return $this.ReadRequest($relativePathUri, $queryHashtable);
    }

    [psobject[]] ReadCompanyContacts ([uint32] $companyId)
    {
        return $this.ReadCompanyContacts($companyId, $null);
    }

    [psobject[]] ReadCompanyContacts ([uint32] $companyId, [string[]] $fields)
    {
        return $this.ReadCompanyContacts($companyId, $fields, 1);
    }

    [psobject[]] ReadCompanyContacts ([uint32] $companyId, [string[]] $fields, [uint32] $pageNum)
    {
        return $this.ReadCompanyContacts($companyId, $fields, $pageNum, 0);
    }

    [psobject[]] ReadCompanyContacts ([uint32] $companyId, [string[]] $fields, [uint32] $pageNum, [uint32] $pageSize)
    {
        return $this.ReadCompanyContacts($companyId, $fields, $null, $pageNum, $pageSize);
    }

    [psobject[]] ReadCompanyContacts ([uint32] $companyId, [string[]] $fields, [string] $orderBy, [uint32] $pageNum, [uint32] $pageSize)
    {
        $query = "company/id=$companyId";
        return $this.ReadContacts($query, $fields, $orderBy, $pageNum, $pageSize);
    }

    [psobject[]] ReadContacts ([string] $companyConditions)
    {
        return $this.ReadContacts($companyConditions, $null);
    }

    [psobject[]] ReadContacts ([string] $companyConditions, [string[]] $fields)
    {
        return $this.ReadContacts($companyConditions, $fields, 1);
    }

    [psobject[]] ReadContacts ([string] $companyConditions, [string[]] $fields, [uint32] $pageNum)
    {
        return $this.ReadContacts($companyConditions, $fields, $fields, 0);
    }

    [psobject[]] ReadContacts ([string] $companyConditions, [string[]] $fields,  [uint32] $pageNum, [uint32] $pageSize)
    {
        return $this.ReadContacts($companyConditions, $fields, $null, $fields, $pageSize);
    }

    [psobject[]] ReadContacts ([string] $companyConditions, [string[]] $fields, [string] $orderBy, [uint32] $pageNum, [uint32] $pageSize)
    {
        [hashtable] $queryHashtable = @{
            conditions = $companyConditions;
            page       = $pageNum;
            pageSize   = $pageSize;
            fields     = $null;
            orderBy    = $orderBy;
        }

        if ($null -ne $fields)
        {
            $queryHashtable.fields = ([string] [String]::Join(",", $fields)).TrimEnd(",");
        }

        return $this.ReadRequest($null, $queryHashtable);
    }

    [uint32] GetContactCount([uint32] $companyId)
    {
        [string] $query = "company/id=$companyId";
        return $this.GetContactCount($query);
    }

    [uint32] GetContactCount([string] $companyConditions)
    {
        return $this.GetCount($companyConditions);
    }

}

class CwApiTimeEntrySvc : CWApiRestClientSvc
{
    CwApiTimeEntrySvc ([CWApiRestSession] $session) : base($session)
    {
        $this.CWApiClient.RelativeBaseEndpointUri = "/time/entries";
    }

    [psobject] ReadTimeEntry ([uint32] $timeEntryId)
    {
        $relativePathUri = "/$timeEntryId";
        return $this.ReadRequest($relativePathUri, $null);
    }

    [psobject[]] ReadTimeEntries ([uint32] $ticketId)
    {
        return $this.ReadTimeEntries($ticketId, 1, 0)
    }

    [psobject[]] ReadTimeEntries ([uint32] $ticketId, [uint32] $pageNum, [uint32] $pageSize)
    {
        $TicketExtendedSvc = [CwApiServiceTicketExtendedSvc]::New($this.CWApiClient.CWConnectionInfo);
        [psobject[]] $ticketEntries = $TicketExtendedSvc.ReadTicketTimeEntries($ticketId, $pageNum, $pageSize);

        if ($ticketEntries.Count -eq 0)
        {
            return $null;
        }

        [string] $ids = ""
        for ($i = 0; $i -lt $ticketEntries.Count; $i++)
        {
            $ids += [string] $ticketEntries[$i].id;

            if ($i -lt $ticketEntries.Count - 1)
            {
                $ids += ",";
            }
        }

        [hashtable] $queryHashtable = @{
            conditions = "id in ($ids)";
        }

        return $this.ReadRequest($null, $queryHashtable);
    }

    [psobject[]] ReadBasicTimeEntries ([uint32] $ticketId, [uint32] $pageNum, [uint32] $pageSize)
    {
        $TicketExtendedSvc = [CwApiServiceTicketExtendedSvc]::New($this.CWApiClient.CWConnectionInfo);
        [psobject[]] $ticketEntries = $TicketExtendedSvc.ReadTicketTimeEntries($ticketId, $pageNum, $pageSize);

        if ($ticketEntries.Count -eq 0)
        {
            return $null;
        }

        return $ticketEntries;
    }

    [psobject[]] CreateTimeEntry ([uint32] $ticketId, [DateTime] $start, [DateTime] $end,  [string] $message, [CWServiceTicketNoteTypes[]] $addTo, [uint32] $memberId, [string] $billOption)
    {
        $data = @{
            TicketID   = $ticketId;
            Start      = $start;
            End        = $end;
            Message    = $message;
            AddTo      = $addTo;
            MemberID   = $memberId;
            BillOption = $billOption;
        }

        return $this.CreateTimeEntry($data);
    }

    [psobject[]] CreateTimeEntry ([hashtable] $timeEntryData)
    {
        $ticketId      = $timeEntryData.TicketID;
        $start         = $timeEntryData.Start;
        $end           = $timeEntryData.End;
        $message       = $timeEntryData.Message;
        $addTo         = $timeEntryData.AddTo;
        $internalNotes = $timeEntryData.InternalNotes;
        $companyID     = $timeEntryData.CompanyID;
        $memberId      = $timeEntryData.MemberID;
        $chargeToType  = $timeEntryData.ChargeToType;
        $billOption    = $timeEntryData.BillOption;


        $TicketSvc = [CwApiServiceTicketSvc]::New($this.CWApiClient.CWConnectionInfo);
        $ticket =  $TicketSvc.ReadTicket($ticketId);
        [psobject[]] $postedEntries = @();


        [hashtable[]] $entries = Split-TimeSpan -Start $start -End $end -UniversalTime;

        for ($i = 0; $i -lt $entries.Count; $i++)
        {
            $entry = $entries[$i];

            [hashtable] $timeEntryInfo = @{
                ChargeToType           = $ticket.recordType;
                ChargeToId             = $ticket.id;
                TimeStart              = (Get-Date $entry.Start).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ');
                TimeEnd                = (Get-Date $entry.End).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ');
                Company                = [pscustomobject] @{ id = $ticket.company.id };
                Member                 = @{ $true = [pscustomobject] @{ id = $memberId }; $false = $null }[ ![String]::IsNullOrEmpty($memberId) ];
                BillableOption         = @{ $true = [string]$billOption; $false = 'DoNotBill' }[ ![String]::IsNullOrEmpty($billOption) ];
            }

            if ($i -eq $entries.Count - 1)
            {
                # only include the messaging if it is the last time entries to add to the ticket
                $timeEntryInfo.Add("Notes", [string]$message);
                $timeEntryInfo.Add("AddToDetailDescriptionFlag", [CWServiceTicketNoteTypes]::Description -in $addTo);
                $timeEntryInfo.Add("AddToInternalAnalysisFlag", [CWServiceTicketNoteTypes]::Internal -in $addTo);
                $timeEntryInfo.Add("AddToResolutionFlag", [CWServiceTicketNoteTypes]::Resolution -in $addTo);

                # add internal note if there was more than one time entries for this space
                $internalMessage = "$internalNotes `r`n`r`n[Note: #$($i + 1) of $($entries.Count) Time Entries: $($start.ToString('yyyy-MM-dd HH:mm:ss')) to $($end.ToString('yyyy-MM-dd HH:mm:ss'))] ";
                $timeEntryInfo.Add("internalNotes", [string]$internalMessage);
            }
            else
            {
                $timeEntryInfo.Add("Notes", [string]$message);
                $timeEntryInfo.Add("AddToDetailDescriptionFlag", [CWServiceTicketNoteTypes]::Description -in $addTo);
                $timeEntryInfo.Add("AddToInternalAnalysisFlag", [CWServiceTicketNoteTypes]::Internal -in $addTo);
                $timeEntryInfo.Add("AddToResolutionFlag", [CWServiceTicketNoteTypes]::Resolution -in $addTo);

                # include internal notes this is one of multiple time entires
                $internalMessage = "$internalNotes `r`n`r`n[Note: #$($i + 1) of $($entries.Count) Time Entries: $($start.ToString('yyyy-MM-dd HH:mm:ss')) to $($end.ToString('yyyy-MM-dd HH:mm:ss'))]";
                $timeEntryInfo.Add("internalNotes", [string]$internalMessage);

                # disable email notification on the these times entries
                $timeEntryInfo.Add("emailResourceFlag", $false);
                $timeEntryInfo.Add("emailContactFlag", $false);
                $timeEntryInfo.Add("emailCcFlag", $false);
            }

            $postedEntries += $this.CreateRequest($null, $timeEntryInfo);
        }

        return $postedEntries;
    }

    [pscustomobject] UpdateTimeEntry ([uint32] $timeEntryId, $start, $end, [string] $message, [string] $internalNote, [uint32] $memberId)
    {
        if ($null -ne $start)
        {
            $start = (Get-Date $start).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        }

        if ($null -ne $end)
        {
            $end = (Get-Date $end).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ');
        }

        $data = [hashtable] @{
            TimeStart     = @{ $true = $start; $false = $null }[ $null -ne $start ];
            TimeEnd       = @{ $true = $end; $false = $null }[ $null -ne $end ];
            Notes         = [string]$message;
            InternalNotes = [string]$internalNote;
        }

        if ($null -ne $memberId -and $memberId -gt 0)
        {
            $data.Add('member', [pscustomobject] @{  Id = $memberId; } );
        }

        $timeEntryUpdateInfo = [PSCustomObject] $data;
        $relativePathUri = "/$timeEntryId";
        $UpdateTimeEntry = $this.UpdateRequest($relativePathUri, $timeEntryUpdateInfo)

        return $UpdateTimeEntry;
    }

    [bool] DeleteTimeEntry ([uint32] $timeEntryId)
    {
        $relativePathUri = "/$timeEntryId";
        return $this.DeleteRequest($relativePathUri);
    }

    [uint32] GetTimeEntryCount ([uint32] $ticketID)
    {
        $TicketExtendedSvc = [CwApiServiceTicketExtendedSvc]::New($this.CWApiClient.CWConnectionInfo);
        return $TicketExtendedSvc.ReadTicketTimeEntryCount($ticketId);
    }

    [uint32] GetTimeEntryCount ([string] $conditions)
    {
        return $this.GetCount($conditions);
    }

}

class CwApiSystemMemberSvc : CWApiRestClientSvc
{
    CwApiSystemMemberSvc ([CWApiRestSession] $session) : base($session)
    {
        $this.CWApiClient.RelativeBaseEndpointUri = "/system/members";
    }

    [psobject] ReadMember ([uint32] $memberId)
    {
        $relativePathUri = "/$memberId";
        return $this.ReadRequest($relativePathUri, $null);
    }

    [psobject] ReadMember ([uint32] $memberId, [string[]] $fields)
    {
        [hashtable] $queryHashtable = @{}

        if ($null -ne $fields)
        {
            $queryHashtable["fields"] = ([string] [String]::Join(",", $fields)).TrimEnd(",");
        }

        $relativePathUri = "/$memberId";
        return $this.ReadRequest($relativePathUri, $queryHashtable);
    }

    [psobject] ReadMember ([string] $username)
    {
        return $this.ReadMember($username, $null);
    }

    [psobject] ReadMember ([string] $username, [string[]] $fields)
    {
        $filter = "identifier='$username'";
        $member = @( $this.ReadMembers($filter, $fields) );

        if ($null -eq $member -or $member.Count -eq 0)
        {
            return $null
        }

        return $member[0];
    }

    [psobject[]] ReadMembers ([string] $memberConditions)
    {
        return $this.ReadMembers($memberConditions, $null);
    }

    [psobject[]] ReadMembers ([string] $memberConditions, [string[]] $fields)
    {
        return $this.ReadMembers($memberConditions, $fields, 1);
    }

    [psobject[]] ReadMembers ([string] $memberConditions, [string[]] $fields, [uint32] $pageNum)
    {
        return $this.ReadMembers($memberConditions, $fields, $pageNum, 0);
    }

    [psobject[]] ReadMembers ([string] $memberConditions, [string[]] $fields, [uint32] $pageNum, [uint32] $pageSize)
    {
        return $this.ReadMembers($memberConditions, $fields, $null, $pageNum, $pageSize);
    }

    [psobject[]] ReadMembers ([string] $memberConditions, [string[]] $fields, [string] $orderBy, [uint32] $pageNum, [uint32] $pageSize)
    {
        [hashtable] $queryHashtable = @{
            conditions = $memberConditions;
            page       = $pageNum;
            pageSize   = $pageSize;
            orderBy    = $orderBy;
        }

        if ($null -ne $fields -and $fields.Count -gt 0)
        {
            $queryHashtable.fields = ([string] [String]::Join(",", $fields)).TrimEnd(",");
        }

        return $this.ReadRequest($null, $queryHashtable);
    }

    [uint32] GetMemberCount([string] $memberConditions)
    {
        return $this.GetCount($memberConditions);
    }

}