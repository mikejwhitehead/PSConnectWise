# remove module if it exist and re-imports it
$WorkspaceRoot = $(Get-Item $PSScriptRoot).Parent.FullName
Remove-Module "PSConnectWise" -ErrorAction Ignore
Import-Module "$WorkspaceRoot\PSConnectWise\PSConnectWise.psm1" -Force 

Describe 'CWSystemMember' {
		
	. $($WorkspaceRoot + '\test\LoadTestSettings.ps1');
	[hashtable] $pstrSharedValues = @{};

	# get the server connnection
	Set-CWSession -Domain $pstrSvrDomain -CompanyName $pstrSvrCompany -PublicKey $pstrSvrPublic -PrivateKey $pstrSvrPrivate;
	
	Context 'Get-CWSystemMember' {
		
		$pstrMemberIDs  = $pstrGenSys.memberIds;
		$pstrMemberID   = $pstrGenSys.memberIds[0];
	
		It 'gets member and checks for the id field' {
			$memberID = $pstrMemberID;
			$member = Get-CWSystemMember -ID $memberID;
			$pstrSharedValues.Add("member", $member);
			$pstrSharedValues.member.id | Should Be $memberID;		
		}
		
		It 'gets member and pipes it through the Select-Object cmdlet for the id property' {
			$memberID = $pstrMemberID;
			$member = Get-CWSystemMember -ID $memberID;
			$member | Select-Object -ExpandProperty id | Should Be $memberID;		
		}
		
		It 'gets members by passing array of member ids to the -ID param' {
			$memberIDs = $pstrMemberIDs;
			$members = Get-CWSystemMember -ID $memberIDs;
			$members | Measure-Object | Select-Object -ExpandProperty Count | Should Be $memberIDs.Count;		
		}
		
		It 'gets list of members that were piped to the cmdlet' {
			$memberIDs = $pstrMemberIDs;
			$members = $memberIDs | Get-CWSystemMember;
			$members | Measure-Object | Select-Object -ExpandProperty Count | Should Be $memberIDs.Count;		
		}
		
		It 'gets member based on the -Filter param' {
			$filter = "id = $pstrMemberID";
			$member = Get-CWSystemMember -Filter $filter;
			$member.id | Should Be $pstrMemberID;		
		}
		
		It 'gets member based on the -Filter param and uses the SizeLimit param' {
			$filter = "id IN ($([String]::Join(",", $pstrMemberIDs)))";
			$sizeLimit =  [Math]::Min($pstrMemberIDs.Count, 2);
			$members = Get-CWSystemMember -Filter $filter -SizeLimit $sizeLimit;
			$members | Measure-Object | Select-Object -ExpandProperty Count | Should Be $sizeLimit;
		}
		
		It 'gets members and sorts member id by descending piping cmdlet through Sort-Object cmdlet' {
			$memberIDs = $pstrMemberIDs;
			$members = Get-CWSystemMember -ID $memberIDs | Sort-Object -Descending id;
			$maxMemberId = $memberIDs | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
			$members[0].id | Should Be $maxMemberId;		
		}
		
		It 'get member using username parameter via Filter and SizeLimit parameter' {
			$sizeLimit = 5;
			$members = Get-CWSystemMember -Filter "identifier='$($pstrSharedValues.member.identifier;)'" -SizeLimit $sizeLimit;
			$null -ne $members | Should Be $true;
		}
		
		It 'get single member by First and Last parameters' {
			$memberFName = $pstrSharedValues.member.FirstName;
			$memberLName = $pstrSharedValues.member.LastName;
			$members = Get-CWSystemMember -FirstName $memberFName -LastName $memberLName;
			$null -ne $members | Should Be $true;
		}
		
		It 'get single member by Username parameter' {
			$username = $pstrSharedValues.member.identifier;
			$members = Get-CWSystemMember -Username $username;
			$null -ne $members | Should Be $true;
		}
	}

} 