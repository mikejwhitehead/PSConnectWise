#dot-source import the classes
. "$PSScriptRoot\Private\PSCWApiClasses.ps1"

# Load and Export the Functions 
#   Credit: https://github.com/RamblingCookieMonster/PSStackExchange

#Get public and private function definition files.
    $Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
    $Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
    Foreach($psfunction in @($Public + $Private))
    {
        Try
        {
            . $psfunction.fullname
        }
        Catch
        {
            Write-Error -Message "Failed to import function $($psfunction.fullname): $_"
        }
    }

# Here I might...
    # Read in or create an initial config file and variable
    # Export Public functions ($Public.BaseName) for WIP modules
    # Set variables visible to the module and its functions only

Export-ModuleMember -Function $Public.Basename
