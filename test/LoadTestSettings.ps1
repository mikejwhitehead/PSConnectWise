# load the settings
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName;
$testSettings = Get-Content -Path "$WorkspaceRoot\testSettings.json" | ? { $_.Trim() -notlike '//*' } | Out-String | ConvertFrom-Json;

# define shorter parent names for the variable scopes
$pstrSvr           = $testSettings.server;
$pstrGenSvc        = $testSettings.general.service;
$pstrProcNewTicket = $testSettings.actions.newTicket;
$pstrComp          = $testSettings.general.company;

# defining server variables
$pstrSvrUrl     = $pstrSvr.url;
$pstrSvrCompany = $pstrSvr.companyName;
$pstrSvrPrivate = $pstrSvr.privateKey;
$pstrSvrPublic  = $pstrSvr.publicKey;

