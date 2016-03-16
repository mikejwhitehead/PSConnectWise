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
    
    CWApiRequestInfo()
    {
        # empty constr    
    }
    
    CWApiRequestInfo([string] $HttpVerb)
    {
        $this.Verb = $HttpVerb;
    }
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
    
    CWApiRestClient([string] $baseUrl, [string] $pathUri, [string] $companyName, [string] $publicKey, [string] $privateKey)
    {
        $this.HttpBaseUrl = $baseUrl;
        $this.HttpBasePathUri = $pathUri;
        $this.CWCompanyName = $companyName;
        $this.CWApiPublicKey = $publicKey;
        $this.CWApiPrivateKey = $privateKey;
        
        $this._validateCWApiRequestParams();
        
        $this.HttpHeader = $this._buildHttpHeader();
    }
    
    CWApiRestClient([string] $baseUrl, [string] $pathUri, [hashtable] $header, [string] $companyName, [string] $publicKey, [string] $privateKey)
    {
        $this.CWApiRestClient($baseUrl, $pathUri, $companyName, $publicKey, $privateKey);
        transformHttpHeader($header);
    }
    
    [pscustomobject] Request([CWApiRequestInfo] $request)
    {
        $header = $this.HttpHeader;
        $url    = $this.BuildUrl($request.RelativePathUri, $request.QueryString);
        $verb   = $request.Verb;
        
        if ($request.QueryString -ne $null)
        {
            $body = $request.Body | ConvertTo-Json -Depth 100 | Out-String; 
        }
        else
        {
            $body = $null;     
        }
        
        $client = [WebRestApiRequest]::new($header, $url, $verb, $body);
        $response = $client.Invoke();
        return $response;
    }
    
    static hidden [string] buildCWQueryString([hashtable] $queryParams)
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
        
    [string] BuildUrl([string] $relativePathUri, [string] $queryString)
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
    
    hidden transformHttpHeader([hashtable] $transformHeaderHashtable)
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
    
    hidden [hashtable] _buildHttpHeader() 
    {
        $header = [hashtable] @{
            "Authorization"    = $this._createCWAuthenticationString();
            "Accept"           = "application/vnd.connectwise.com+json; version=v2015_3";
            "Type"             = "application/json"; 
            "x-cw-overridessl" = "True";
        }
        
        return $header;
    }

    hidden [string] _createCWAuthenticationString()
    {   
        [string] $encodedString = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}+{1}:{2}" -f $this.CWCompanyName, $this.CWApiPublicKey, $this.CWApiPrivateKey)));
        return [String]::Format("Basic {0}", $encodedString);
    }
    
    hidden [void] _validateCWApiRequestParams()
    {
        [string[]] $requiredProperties = @("HttpBaseUrl", "HttpBasePathUri", "CWCompanyName", "CWApiPublicKey", "CWApiPrivateKey");
        
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

class CwApiServiceTicketSvc
{
    hidden [CWApiRestClient] $CWApiClient; 
    
    CwApiServiceTicketSvc([string] $baseUrl, [string] $companyName, [string] $publicKey, [string] $privateKey)
    {
        [string] $basePathUri = "/service/tickets";
        $this.CWApiClient = [CWApiRestClient]::new($baseUrl, $basePathUri, $companyName, $publicKey, $privateKey);
    }
    
    [pscustomobject] ReadTicket([int] $ticketId)
    {
        return $this.ReadTicket($ticketId, "*");
    }
    
    [pscustomobject] ReadTicket([int] $ticketId, [string[]] $fields)
    {
        [hashtable] $queryParams = @{ 
            fields = ([string] [String]::Join(",", $fields)).TrimEnd(",");
        }
        [string] $queryString = [CWApiRestClient]::buildCWQueryString($queryParams);
        
        $request = [CWApiRequestInfo]::new("GET");
        $request.RelativePathUri = "/$ticketID";
        $request.QueryString     = $queryString
        
        return $this.read($request);
    }
    
    [pscustomobject[]] ReadTickets([string] $ticketQuery)
    {
        return $this.ReadTickets($ticketQuery, "*");
    }
    
    [pscustomobject[]] ReadTickets([string] $ticketQuery, [string[]] $fields)
    {
        [hashtable] $queryParams = @{
            conditions = $ticketQuery
            fields     = ([string] [String]::Join(",", $fields)).TrimEnd(",");
        }
        [string] $queryString = [CWApiRestClient]::buildCWQueryString($queryParams);
        
        $request = [CWApiRequestInfo]::new("GET");
        $request.QueryString = $queryString;
        
        return $this.read($request);
    }
    
    hidden [pscustomobject] read([CWApiRequestInfo] $requestHashtable) 
    {
        $ticket = $this.CWApiClient.Request($requestHashtable);
        return $ticket; 
    }
  
}

function Get-CWServiceTicket 
{
    [CmdLetBinding()]
    param
    (
        [Parameter(ParameterSetName='SingleTicket', Position=0, Mandatory=$true)]
        [Parameter(ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [int[]]$TicketID,
        [Parameter(ParameterSetName='TicketQuery', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Query,
        [Parameter(ParameterSetName='SingleTicket', Position=1, Mandatory=$false)]
        [Parameter(ParameterSetName='TicketQuery', Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Fields,
        #[Parameter(ParameterSetName='TicketQuery', Mandatory=$false)]
        #[string]$OrderBy,
        #[Parameter(ParameterSetName='TicketQuery', Mandatory=$false)]
        #[int]$Page,
        #[Parameter(ParameterSetName='TicketQuery', Mandatory=$false)]
        #[int]$PageSize,
        [Parameter(ParameterSetName='SingleTicket', Position=2, Mandatory=$true)]
        [Parameter(ParameterSetName='TicketQuery', Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$BaseApiUrl,
        [Parameter(ParameterSetName='SingleTicket', Position=3, Mandatory=$true)]
        [Parameter(ParameterSetName='TicketQuery', Position=2, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$CompanyName,
        [Parameter(ParameterSetName='SingleTicket', Position=4, Mandatory=$true)]
        [Parameter(ParameterSetName='TicketQuery', Position=3, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PublicKey,
        [Parameter(ParameterSetName='SingleTicket', Position=5, Mandatory=$true)]
        [Parameter(ParameterSetName='TicketQuery', Position=4, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PrivateKey
    )
    
    Begin
    {
        $TicketSvc = [CwApiServiceTicketSvc]::new($BaseApiUrl, $CompanyName, $PublicKey, $PrivateKey);
    }
    Process
    {
        if (![String]::IsNullOrWhiteSpace($Query))
        {
            Write-Debug "Requesting Ticket IDs that Meets this Query: $Query";
            $queriedTickets = $TicketSvc.ReadTickets($Query, [string[]] @("id"));
            [int[]] $TicketID = $queriedTickets.id
        }
        
        # determines if to select all fields or specific fields
        [string[]] $selectedFields = $null;
        if ($Fields -ne $null)
        {
            if (!($Fields.Length -eq 1 -and $Fields[0].Trim() -ne "*"))
            {
                # TODO add parser for valid fields only
                $selectedFields = $Fields;
            }
        }
        
        if ($TicketID -ne $null)
        {
            Write-Debug "Retrieving ConnectWise Tickets by Ticket ID"
            foreach ($ticket in $TicketID)
            {
                Write-Verbose "Requesting ConnectWise Ticket Number: $ticket";
                if ($selectedFields -eq $null -or $selectedFields.Length -eq 0)
                {
                    $TicketSvc.ReadTicket($ticket);
                }
                else 
                {
                    $TicketSvc.ReadTicket($ticket, $selectedFields);
                }
            }
        }
    }
    End
    {
        # do nothing here
    }
}

Export-ModuleMember -Function 'Get-CWServiceTicket';