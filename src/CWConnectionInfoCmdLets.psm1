#dot-source import the classes
. "$PSScriptRoot\PSCWApiClasses.ps1"

function Get-CWConnectionInfo
{
    [CmdLetBinding()]
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
        [switch]$Override
    )
    
    Begin
    {
        [CWApiRestConnectionInfo] $connectionInfo;
        
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
        
        return $connectionInfo;
        
    }
    End
    {
        # do nothing here
    }    
}

Export-ModuleMember -Function 'Get-CWConnectionInfo';