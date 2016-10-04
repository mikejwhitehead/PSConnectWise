<#
.SYNOPSIS
    Return object with API connection information to the ConnectWise server.
.PARAMETER Domain
    Fully qualify domain name of the ConnectWise (API) server
.PARAMETER CompanyName
    ConnectWise company name
.PARAMETER PublicKey
    ConnectWise API public key
.PARAMETER PrivateKey
    ConnectWise API private key
.EXAMPLE
    $CWSession = Set-CWSession -Domain "cw.example.com" -CompanyName "ExampleInc" -PublicKey "VbN85MnY" -PrivateKey "ZfT05RgN";
#>
function Set-CWSession
{
    [CmdLetBinding()]
    [OutputType("CWApiRestSession", ParameterSetName="Normal")]
    param
    (
        [Parameter(ParameterSetName='Normal', Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Domain,
        [Parameter(ParameterSetName='Normal', Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$CompanyName,
        [Parameter(ParameterSetName='Normal', Position=2, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PublicKey,
        [Parameter(ParameterSetName='Normal', Position=3, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PrivateKey,
        [Parameter(ParameterSetName='Normal', Mandatory=$false)]
        [switch]$OverrideSSL
    )
    
    Begin
    {
        [CWApiRestSession] $cwSession = $null;
        
        if ($Override)
        {
            $cwSession = [CWApiRestSession]::New($Domain, $CompanyName, $PublicKey, $PrivateKey);
        }
        else 
        {
            $cwSession = [CWApiRestSession]::New($Domain, $CompanyName, $PublicKey, $PrivateKey, $true);
        }
    }
    Process
    {
        [PSObject]$Script:CWSession = $cwSession
        $cwSession;
    }
    End
    {
        # do nothing here
    }    
}

Export-ModuleMember -Function 'Set-CWSession';