[CmdletBinding()]
Param (
    [string]$InstallPath = $(
        if (!$IsMacOs){
            (Join-Path $env:ProgramFiles 'WindowsPowerShell\Modules\PSConnectWise')
        } else {
            (Join-Path '/usr/local/share/powershell/Modules' '/PSConnectWise')
        }),
    [switch]$Force
)


$sourceFiles = @(
    '.\PSConnectWise\bin',
    '.\PSConnectWise\en-US',
    '.\PSConnectWise\Private',
    '.\PSConnectWise\Public',
    '.\PSConnectWise\PSConnectWise.ps*'
)

if (Test-Path $InstallPath) {
    if ($Force) {
        Remove-Item -Path $InstallPath\* -Recurse
    } else {
        Write-Warning "Module already installed at `"$InstallPath`" use -Force to overwrite installation."
        return
    }
} else {
    New-Item -Path $InstallPath -ItemType Directory | Out-Null
}

Push-Location $PSScriptRoot

Copy-Item -Path $sourceFiles -Destination $InstallPath -Recurse

Pop-Location

Import-Module -Name PSConnectWise -Verbose