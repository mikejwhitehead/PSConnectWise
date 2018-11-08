## Import PSConnectWise Module ##
Import-Module D:\Development\code\PSConnectWise\PSConnectWise\PSConnectWise.psm1

## New Connect Wise Contact Info ##
$FirstName = "$[FirstName]"
$LastName = "$[LastName]"
$Title = "$[Title]"
$InactiveFlag = $[InactiveFlag]
$EmailAddress = "$[EmailAddress]"
$PhoneNumber = "$[PhoneNumber]"
$CompanyID = "$[CompanyID]"
$SiteId = "$[SiteID]"

## Create Connect Wise Session ##
$cwSession = Set-CWSession -Domain "$[ConnectWise Server]" -CompanyName "$[ConnectWise Company Name]" -PublicKey "$[ConnectWise API Public Key]" -PrivateKey "$[ConnectWise API Private Key]"

## Create Connect Contact ##

if ($PhoneNumber -eq "") {
    $newContact = New-CWCompanyContact -FirstName $FirstName -LastName $LastName -InactiveFlag $InactiveFlag -Title $Title -EmailAddress $EmailAddress -CompanyId $CompanyID -SiteId $SiteId
}
else {
    $newContact = New-CWCompanyContact -FirstName $FirstName -LastName $LastName -InactiveFlag $InactiveFlag -Title $Title -EmailAddress $EmailAddress -PhoneNumber $PhoneNumber -CompanyId $CompanyID -SiteId $SiteId
}

$global:ContactID = $newContact.id