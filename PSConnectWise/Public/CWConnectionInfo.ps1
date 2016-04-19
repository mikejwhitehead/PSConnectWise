function Get-CWConnectionInfo
{
    [CmdLetBinding()]
    [OutputType("CWApiRestConnectionInfo", ParameterSetName="Normal")]
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
        [CWApiRestConnectionInfo] $connectionInfo = $null;
        
        if ($Override)
        {
            $connectionInfo = [CWApiRestConnectionInfo]::New($Domain, $CompanyName, $PublicKey, $PrivateKey);
        }
        else 
        {
            $connectionInfo = [CWApiRestConnectionInfo]::New($Domain, $CompanyName, $PublicKey, $PrivateKey, $true);
        }
    }
    Process
    {
        $connectionInfo
    }
    End
    {
        # do nothing here
    }    
}

Export-ModuleMember -Function 'Get-CWConnectionInfo';