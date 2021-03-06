<#  
.SYNOPSIS  
    This script creates users via ADSI   
.DESCRIPTION  
    This script creates objects with DirSync errors via ADSI.
.NOTES  
    File Name  : Set-IdFixErrors.ps1  
    Author     : Bill Ashcraft - billash@microsoft.com  
    Requires   : PowerShell Version 2.0  
	
	If you use the script with defaults and filter IdFix down to just OU1
	then as a spot check MT should yield 16 errrors and D should yield 19.
.EXAMPLE  
	Generate invalid character tests with default domain namespace contoso.com
    PS C:\Users\Billash> .\Set-IdFixErrors.ps1 
.EXAMPLE  
	Generate invalid character tests with vanity domain namespace e2k10.com
    PS C:\Users\Billash> .\Set-IdFixErrors.ps1 -domain e2k10.com 
.EXAMPLE  
	Generate invalid character tests and bulk user, contact, and group errors
	with vanity domain namespace e2k10.com
    PS C:\Users\Billash> .\Set-IdFixErrors.ps1 -domain e2k10.com -ou 5 -user 200
#>  

<#
 CURRENT RULES:
`
 displayName
	(D) not blank for group
	(D) no leading or trailing whitespace
	(D) less than 256
 mail
	(D) less than 256
	(D) invalid chars (whitespace), rfc2822 & routable, no duplicates
 mailNickName
	(MT/D) invalid chars (whitespace \ ! # $ % & * + / = ? ^ ` { } | ~ < > ( ) ' ; : , [ ] " @), no duplicates, no leading or trailing periods, less than 64
	(D) not blank for contact
	(D) not blank for user
 proxyAddresses
	(MT/D) rfc822 & routable for smtp proxies, no duplicates, less than 256
 sAMAccountName
	(MT) invalid chars (\ " | , / [ ] : < > + = ; ? *), no duplicates, less than 20 for users or 256 all others
 targetAddress
	(MT/D) rfc822 & routable for smtp proxies, no duplicates, less than 256
	(D) not blank for contact, targetAddress must match mail
	(D) not blank for user without homeMdb, targetAddress must match mail
 userPrincipalName
	(MT) invalid chars (whitespace \ % & * + / = ? ` { } | < > ( ) ; : , [ ] "), rfc2822 & routable, no duplicates, less than 64 before @, less than 256 after @
#>
param 
( 
    [string]$domain="contoso.com",
    [int]$ou=1,
    [int]$users=10
)
# ENTER YOUR OWN HOMEMDB
$homeMDB = "CN=Mailbox Database 0922756933,CN=Databases,CN=Exchange Administrative Group (FYDIBOHF23SPDLT),CN=Administrative Groups,CN=Demo,CN=Microsoft Exchange,CN=Services,CN=Configuration,DC=demo,DC=com"

# set the vanity domain namespace
$domain = "@" + $domain

# Get the current AD domain
$adDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain() 
$adsiDomain = [ADSI]($("LDAP://" + $adDomain.FindDomainController().Name + "/dc=" + $($adDomain.Name -replace "\.", ",dc=")))

# Create parent OU
$ouName = "IdFix"
Write-Host "OU:",$ouName
$newOU = $adsiDomain.create("OrganizationalUnit", $("ou=" + $ouName))
$newOU.Put("Description",$ouName)
$newOU.SetInfo()

# Create error OU
$ouName = "Error"
Write-Host
Write-Host "OU:",$ouName
$adsiDomain = [ADSI]($("LDAP://" + $adDomain.FindDomainController().Name + "/ou=IdFix,dc=" + $($adDomain.Name -replace "\.", ",dc=")))
$newOU = $adsiDomain.create("OrganizationalUnit", $("ou=" + $ouName))
$newOU.Put("Description",$ouName)
$newOU.SetInfo()
$adsiOU = [ADSI]($("LDAP://" + $adDomain.FindDomainController().Name + "/ou=" + $ouName +",ou=IdFix,dc=" + $($adDomain.Name -replace "\.", ",dc=")))

$groupCn = "dGroupDisplaynameBlank"
Write-Host "group:",$groupCn
$group = $adsiOU.Create("group", $("cn=" + $groupCn))
$group.Put("mail", $($groupCn+"@lab.com"))
$group.Put("mailNickName", $groupCn)
$group.setinfo()

$groupCn = "dGroupDisplaynameWhitespace"
Write-Host "group:",$groupCn
$group = $adsiOU.Create("group", $("cn=" + $groupCn))
$group.Put("displayName", "  Dedicated group Displayname Whitespace  ")
$group.Put("mail", $($groupCn+"@lab.com"))
$group.Put("mailNickName", $groupCn)
$group.setinfo()

$userCn = "dUserMailWhitespace"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Dedicated user Mail Whitespace")
$user.Put("mail", $("  "+$userCn+"@lab.com  "))
$user.Put("mailNickName", $userCn)
$user.Put("homeMDB", $homeMDB)
$user.setinfo()

$userCn = "dUserMailRfc2822"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Dedicated user Mail Rfc2822")
$user.Put("mail", $($userCn+"@@lab###.local"))
$user.Put("mailNickName", $userCn)
$user.Put("homeMDB", $homeMDB)
$user.setinfo()

$userCn = "dUserMailDup1"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Dedicated user Mail Duplicate1")
$user.Put("mail", $("dUserMailDup1"+"@lab.com"))
$user.Put("mailNickName", $userCn)
$user.Put("homeMDB", $homeMDB)
$user.setinfo()

$userCn = "dUserMailDup2"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Dedicated user Mail Duplicate2")
$user.Put("mail", $("dUserMailDup1"+"@lab.com"))
$user.Put("mailNickName", $userCn)
$user.Put("homeMDB", $homeMDB)
$user.setinfo()

$userCn = "dUserMailnicknameInvalidchars"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Dedicated user Mailnickname Invalidchars")
$user.Put("mail", $($userCn+"@lab.com"))
$user.Put("mailNickName", $("  "+$userCn+"###"))
$user.Put("homeMDB", $homeMDB)
$user.setinfo()

$userCn = "dUserMailnicknamePeriods"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Dedicated user Mailnickname Periods")
$user.Put("mail", $($userCn+"@lab.com"))
$user.Put("mailNickName", $("."+$userCn+"."))
$user.Put("homeMDB", $homeMDB)
$user.setinfo()

$userCn = "dUserMailnicknameDup1"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Dedicated user Mailnickname Duplicate1")
$user.Put("mail", $($userCn+"@lab.com"))
$user.Put("mailNickName", $("dUserMailnicknameDup1"))
$user.Put("homeMDB", $homeMDB)
$user.setinfo()

$userCn = "dUserMailnicknameDup2"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Dedicated user Mailnickname Duplicate2")
$user.Put("mail", $($userCn+"@lab.com"))
$user.Put("mailNickName", $("dUserMailnicknameDup1"))
$user.Put("homeMDB", $homeMDB)
$user.setinfo()

$userCn = "dUserMailnicknameBlank"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Dedicated user Mailnickname Blank")
$user.Put("mail", $($userCn+"@lab.com"))
$user.Put("homeMDB", $homeMDB)
$user.setinfo()

$userCn = "dContactMailnicknameBlank"
Write-Host "contact:",$userCn
$user = $adsiOU.Create("contact", $("cn=" + $userCn))
$user.Put("displayName", "Dedicated contact Mailnickname Blank")
$user.Put("mail", $($userCn+"@lab.com"))
$user.PutEx(3,"targetAddress", @($("SMTP:"+$userCn+"@lab.com")))
$user.setinfo()

$userCn = "dUserProxyRfc2822"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Dedicated user Proxy Rfc2822")
$user.Put("mail", $($userCn+"@lab.com"))
$user.PutEx(3,"proxyAddresses", @($("SMTP:"+$userCn+"@lab.local")))
$user.Put("mailNickName", $userCn)
$user.Put("homeMDB", $homeMDB)
$user.setinfo()

$userCn = "dUserProxyDup1"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Dedicated user Proxy Duplicate1")
$user.Put("mail", $($userCn+"@lab.com"))
$user.PutEx(3,"proxyAddresses", @($("SMTP:dUserProxyDup1@lab.com")))
$user.Put("mailNickName", $userCn)
$user.Put("homeMDB", $homeMDB)
$user.setinfo()

$userCn = "dUserProxyDup2"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Dedicated user Proxy Duplicate2")
$user.Put("mail", $($userCn+"@lab.com"))
$user.PutEx(3,"proxyAddresses", @($("SMTP:dUserProxyDup1@lab.com")))
$user.Put("mailNickName", $userCn)
$user.Put("homeMDB", $homeMDB)
$user.setinfo()

$userCn = "dUserTargetaddressRfc2822"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Dedicated user Targetaddress Rfc2822")
$user.Put("mail", $($userCn+"@lab.com"))
$user.PutEx(3,"targetAddress", @($("SMTP:"+$userCn+"@@lab###.com")))
$user.Put("mailNickName", $userCn)
$user.Put("homeMDB", $homeMDB)
$user.setinfo()

$userCn = "dUserTargetaddressDup1"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Dedicated user Targetaddress Duplicate1")
$user.Put("mail", $($userCn+"@lab.com"))
$user.PutEx(3,"targetAddress", @($("SMTP:dUserTargetaddressDup1@lab.com")))
$user.Put("mailNickName", $userCn)
$user.Put("homeMDB", $homeMDB)
$user.setinfo()

$userCn = "dUserTargetaddressDup2"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Dedicated user Targetaddress Duplicate2")
$user.Put("mail", $($userCn+"@lab.com"))
$user.PutEx(3,"targetAddress", @($("SMTP:dUserTargetaddressDup1@lab.com")))
$user.Put("mailNickName", $userCn)
$user.Put("homeMDB", $homeMDB)
$user.setinfo()

$userCn = "dUserTargetaddressBlank"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Dedicated user Targetaddress Blank")
$user.Put("mail", $($userCn+"@lab.com"))
$user.Put("mailNickName", $userCn)
$user.setinfo()

$userCn = "dContactTargetaddressBlank"
Write-Host "contact:",$userCn
$user = $adsiOU.Create("contact", $("cn=" + $userCn))
$user.Put("displayName", "Dedicated contact Targetaddress Blank")
$user.Put("mail", $($userCn+"@lab.com"))
$user.Put("mailNickName", $userCn)
$user.setinfo()

$userCn = "dContactTargetaddressMailmatch"
Write-Host "contact:",$userCn
$user = $adsiOU.Create("contact", $("cn=" + $userCn))
$user.Put("displayName", "Dedicated contact Targetaddress Blank")
$user.Put("mail", $($userCn+"@lab.com"))
$user.Put("mailNickName", $userCn)
$user.PutEx(3,"targetAddress", @($("SMTP:"+$userCn+"xxx@lab.com")))
$user.setinfo()

$userCn = "dUserTargetaddressMailmatch"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Dedicated contact Targetaddress Blank")
$user.Put("mail", $($userCn+"@lab.com"))
$user.Put("mailNickName", $userCn)
$user.PutEx(3,"targetAddress", @($("SMTP:"+$userCn+"xxx@lab.com")))
$user.setinfo()

$userCn = "mtUserUserPrincipalNameInvalidchars"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Multitenant user userPrincipalName Invalidchars")
$user.Put("mail", $($userCn+"@lab.com"))
$user.Put("userPrincipalName", $($userCn+"&&&@lab&&&.com"))
$user.setinfo()

$userCn = "mtUserUserPrincipalNameRfc2822"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Multitenant user userPrincipalName Rfc2822")
$user.Put("mail", $($userCn+"@lab.com"))
$user.Put("userPrincipalName", $($userCn+"@@lab###.local"))
$user.setinfo()

$userCn = "mtUserUserPrincipalNameDup1"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Multitenant user userPrincipalName Duplicate1")
$user.Put("mail", $($userCn+"@lab.com"))
$user.Put("userPrincipalName", $("mtUserUserPrincipalNameDup1@lab.com"))
$user.setinfo()

$userCn = "mtUserUserPrincipalNameDup2"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Multitenant user userPrincipalName Duplicate2")
$user.Put("mail", $($userCn+"@lab.com"))
$user.Put("userPrincipalName", $("mtUserUserPrincipalNameDup1@lab.com"))
$user.setinfo()

$userCn = "mtUserMailnicknameInvalidchars"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Multitenant user Mailnickname Invalidchars")
$user.Put("mail", $($userCn+"@lab.com"))
$user.Put("mailNickName", $($userCn+"###"))
$user.setinfo()

$userCn = "mtUserMailnicknamePeriods"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Multitenant user Mailnickname Periods")
$user.Put("mail", $($userCn+"@lab.com"))
$user.Put("mailNickName", $("."+$userCn+"."))
$user.setinfo()

$userCn = "mtUserMailnicknameDup1"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Multitenant user Mailnickname Duplicate1")
$user.Put("mail", $($userCn+"@lab.com"))
$user.Put("mailNickName", $("mtUserMailnicknameDup1"))
$user.setinfo()

$userCn = "mtUserMailnicknameDup2"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Multitenant user Mailnickname Duplicate2")
$user.Put("mail", $($userCn+"@lab.com"))
$user.Put("mailNickName", $("mtUserMailnicknameDup1"))
$user.setinfo()

$userCn = "mtUserProxyRfc2822"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Multitenant user Proxy Rfc2822")
$user.Put("mail", $($userCn+"@lab.com"))
$user.PutEx(3,"proxyAddresses", @($("SMTP:"+$userCn+"@lab.local")))
$user.setinfo()

$userCn = "mtUserProxyDup1"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Multitenant user Proxy Duplicate1")
$user.Put("mail", $($userCn+"@lab.com"))
$user.PutEx(3,"proxyAddresses", @($("SMTP:mtUserProxyDup1@lab.com")))
$user.setinfo()

$userCn = "mtUserProxyDup2"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Multitenant user Proxy Duplicate2")
$user.Put("mail", $($userCn+"@lab.com"))
$user.PutEx(3,"proxyAddresses", @($("SMTP:mtUserProxyDup1@lab.com")))
$user.setinfo()

$userCn = "mtUserTargetaddressRfc2822"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Multitenant user Targetaddress Rfc2822")
$user.Put("mail", $($userCn+"@lab.com"))
$user.PutEx(3,"targetAddress", @($("SMTP:"+$userCn+"@@lab###.com")))
$user.setinfo()

$userCn = "mtUserTargetaddressDup1"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Multitenant user Targetaddress Duplicate1")
$user.Put("mail", $($userCn+"@lab.com"))
$user.PutEx(3,"targetAddress", @($("SMTP:mtUserTargetaddressDup1@lab.com")))
$user.setinfo()

$userCn = "mtUserTargetaddressDup2"
Write-Host "user:",$userCn
$user = $adsiOU.Create("user", $("cn=" + $userCn))
$user.Put("displayName", "Multitenant user Targetaddress Duplicate2")
$user.Put("mail", $($userCn+"@lab.com"))
$user.PutEx(3,"targetAddress", @($("SMTP:mtUserTargetaddressDup1@lab.com")))
$user.setinfo()

# Create character OU
$ouName = "Character"
Write-Host
Write-Host "OU:",$ouName
$adsiDomain = [ADSI]($("LDAP://" + $adDomain.FindDomainController().Name + "/ou=IdFix,dc=" + $($adDomain.Name -replace "\.", ",dc=")))
$newOU = $adsiDomain.create("OrganizationalUnit", $("ou=" + $ouName))
$newOU.Put("Description",$ouName)
$newOU.SetInfo()
$adsiOU = [ADSI]($("LDAP://" + $adDomain.FindDomainController().Name + "/ou=" + $ouName +",ou=IdFix,dc=" + $($adDomain.Name -replace "\.", ",dc=")))

# generate user objects to check all characters
$checkArr = @("``", "~", "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "_", "-", "+", "=", "[", "{", "}", "]", "|", "\", ":", ";", """", "'", "<", ",", ">", ".", "?", "/")
#$checkArr = @("-")
foreach ($check in $checkArr)
{
	# assign a readable name
	switch ($check)
	{
		"``"{$cn = "Accent"; break}
		"~"{$cn = "Tilde"; break}
		"!"{$cn = "Exclamation"; break}
		"@"{$cn = "At"; break}
		"#"{$cn = "Hash"; break}
		"$"{$cn = "Dollar"; break}
		"%"{$cn = "Percent"; break}
		"^"{$cn = "Hat"; break}
		"&"{$cn = "Ampersand"; break}
		"*"{$cn = "Asterix"; break}
		"("{$cn = "LeftParan"; break}
		")"{$cn = "RightParan"; break}
		"_"{$cn = "Underscore"; break}
		"-"{$cn = "Hyphen"; break}
		"+"{$cn = "Plus"; break}
		"="{$cn = "Equal"; break}
		"["{$cn = "LeftBracket"; break}
		"{"{$cn = "LeftBrace"; break}
		"}"{$cn = "RightBrace"; break}
		"]"{$cn = "RightBracket"; break}
		"|"{$cn = "Pipe"; break}
		"\"{$cn = "LeftSlash"; break}
		":"{$cn = "Colon"; break}
		";"{$cn = "Semicolon"; break}
		""""{$cn = "DoubleQuote"; break}
		"'"{$cn = "Apostrophe"; break}
		"<"{$cn = "LessThan"; break}
		","{$cn = "Comma"; break}
		">"{$cn = "GreaterThan"; break}
		"."{$cn = "Period"; break}
		"?"{$cn = "Question"; break}
		"/"{$cn = "RightSlash"; break}
	}

	Write-Host "user:",$cn
	
	$char = $cn + $check + "CHAR"
	$user = $adsiOU.Create("user", $("cn=" + $cn))
	
	$user.Put("displayName", $("displayName"+$char))
	$user.Put("givenName", $("givenName"+$char))
	$user.Put("mail", $("mail"+$char+$domain))
	$user.Put("mailNickName", $("mailNickName"+$char))
	$user.PutEx(3,"proxyAddresses", @($("SMTP:"+"proxyAddresses"+$char+$domain)))

	# some characters will not allow sAMAccountName to be generated
	switch ($check)
	{
		"*"{$user.Put("sAMAccountName", $cn); break}
		"+"{$user.Put("sAMAccountName", $cn); break}
		"="{$user.Put("sAMAccountName", $cn); break}
		"["{$user.Put("sAMAccountName", $cn); break}
		"]"{$user.Put("sAMAccountName", $cn); break}
		"|"{$user.Put("sAMAccountName", $cn); break}
		"\"{$user.Put("sAMAccountName", $cn); break}
		":"{$user.Put("sAMAccountName", $cn); break}
		";"{$user.Put("sAMAccountName", $cn); break}
		""""{$user.Put("sAMAccountName", $cn); break}
		"<"{$user.Put("sAMAccountName", $cn); break}
		","{$user.Put("sAMAccountName", $cn); break}
		">"{$user.Put("sAMAccountName", $cn); break}
		"?"{$user.Put("sAMAccountName", $cn); break}
		"/"{$user.Put("sAMAccountName", $cn); break}
		default{$user.Put("sAMAccountName", $char); break}
	}
	
	$user.Put("sn", $("sn"+$char))
	$user.Put("targetAddress", $("smtp:"+"targetAddress"+$char+$domain))
	$user.Put("userPrincipalName", $("userPrincipalName"+$char+$domain))

	$user.SetInfo()
}

# create bulk OU's with users, contacts, and groups
$intUser = 1
for ($i=1; $i -lt $($ou + 1); $i++)
{
	# Create bulk error OU
	$adsiDomain = [ADSI]($("LDAP://" + $adDomain.FindDomainController().Name + "/ou=IdFix,dc=" + $($adDomain.Name -replace "\.", ",dc=")))
	$ouName = "OU" + [STRING]$i
	Write-Host
	Write-Host "OU:",$ouName
	$newOU = $adsiDomain.create("OrganizationalUnit", $("ou=" + $ouName))
	$newOU.Put("Description",$ouName)
	$newOU.SetInfo()
	$adsiOU = [ADSI]($("LDAP://" + $adDomain.FindDomainController().Name + "/ou=" + $ouName +",ou=IdFix,dc=" + $($adDomain.Name -replace "\.", ",dc=")))

	# last user created
	$userLastCn = "000000"

	for ($j=1; $j -lt $($users + 1); $j++)
	{
		#group
		if (([STRING]$j).EndsWith("1"))
		{
			$groupCn = "group" + [STRING]$("{0:D6}" -f $intUser)
			Write-Host "group:",$groupCn
			$group = $adsiOU.Create("group", $("cn=" + $groupCn))
			$group.Put("displayName", $($groupCn+" "+$ouName))
			$group.Put("mail", $($groupCn+"&&&@lab.com"))
			$group.PutEx(3,"proxyAddresses", @($("smtp:"+$groupCn+$domain)))
			$group.setinfo()
		}
		elseif (([STRING]$j).EndsWith("6"))
		{
			$groupCn = "group" + [STRING]$("{0:D6}" -f $intUser)
			Write-Host "group:",$groupCn
			$group = $adsiOU.Create("group", $("cn=" + $groupCn))
			$group.Put("mail", $($groupCn+$domain))
			$group.PutEx(3,"proxyAddresses", @($("SMTP:"+$groupCn+$domain)))
			$group.setinfo()
		}

		#contact
		if (([STRING]$j).EndsWith("9"))
		{
			$contactCn = "contact" + [STRING]$("{0:D6}" -f $intUser)
			Write-Host "contact:",$contactCn
			$contact = $adsiOU.Create("contact", $("cn=" + $contactCn))
			$contact.Put("displayName", $($contactCn+" "+$ouName))
			$contact.Put("mail", $($contactCn+"$%&*+@lab.net"))
			$contact.Put("mailNickName", $contactCn)
			$contact.setinfo()
			$group.add($contact.ADsPath)
			$group.setinfo()
		}
		elseif (([STRING]$j).EndsWith("0"))
		{
			$contactCn = "contact" + [STRING]$("{0:D6}" -f $intUser)
			Write-Host "contact:",$contactCn
			$contact = $adsiOU.Create("contact", $("cn=" + $contactCn))
			$contact.Put("mail", $($contactCn+"$%&*+@lab.com"))
			$contact.Put("targetAddress", $($contactCn+"$%&*+@lab.com"))
			$contact.PutEx(3,"proxyAddresses", @($("smtp:"+$contactCn+$domain)))
			$contact.setinfo()
		}

		# users
		$userCn = "user" + [STRING]$("{0:D6}" -f $intUser++)
		Write-Host "user:",$userCn
		$user = $adsiOU.Create("user", $("cn=" + $userCn))
		$user.Put("displayName", $($userCn+" "+$ouName))
		
		# mail
		if ([int]$userCn.substring(6) -le 6)
		{
			$user.Put("mail", $($userCn+$domain))
		}
		elseif ([int]$userCn.substring(6) -eq 7)
		{
			$user.Put("mail", $("  "+$userCn+$domain))
		}
		elseif ([int]$userCn.substring(6) -eq 8)
		{
			$user.Put("mail", $($userCn+$domain))
		}
		elseif ([int]$userCn.substring(6) -eq 9)
		{
			$user.Put("mail", $($userLastCn+$domain))
		}
		elseif ($userCn.EndsWith("0"))
		{
			$user.Put("mail", $($userCn+"###?@+lab.local"))
		}
		
		# mailNickName
		if ([int]$userCn.substring(6) -le 5)
		{
			$user.Put("mailNickName", $userCn)
		}
		elseif ([int]$userCn.substring(6) -eq 7)
		{
			$user.Put("mailNickName", $("."+$userCn))
		}
		elseif ([int]$userCn.substring(6) -eq 8)
		{
			$user.Put("mailNickName", $userCn)
		}
		elseif ([int]$userCn.substring(6) -eq 9)
		{
			$user.Put("mailNickName", $userLastCn)
		}
		elseif ($userCn.EndsWith("0"))
		{
			$user.Put("mailNickName", $($userCn+"#"))
		}
		
		# proxyAddresses
		$user.PutEx(3,"proxyAddresses", @($("SMTP:"+$userCn+$domain)))
		if ([int]$userCn.substring(6) -eq 3)
		{
			$user.PutEx(3,"proxyAddresses", @($("smtp:"+$userCn+"@customer.local")))
		}
		if ([int]$userCn.substring(6) -eq 4)
		{
			$user.PutEx(3,"proxyAddresses", @($("    sip:"+$userCn+"@lab.com")))
		}
		if ([int]$userCn.substring(6) -eq 5)
		{
			$user.PutEx(3,"proxyAddresses", @($("NOTES:"+$userCn)))
		}
		if ([int]$userCn.substring(6) -eq 7)
		{
			$user.PutEx(3,"proxyAddresses", @($("smtp:"+$userLastCn+$domain)))
		}
		
#		# sAMAccountName: AD won't allow duplicates to be created in the same domain
#		if ([int]$userCn.substring(6) -le 6)
#		{
#			$user.Put("sAMAccountName", $userCn)
#		}
#		else
#		{
#			$user.Put("sAMAccountName", $userLastCn)
#		}
		
		# targetAddress
		if ([int]$userCn.substring(6) -le 3)
		{
			$user.PutEx(3,"targetAddress", @($("smtp:"+$userCn+$domain)))
		}
		if ([int]$userCn.substring(6) -eq 6)
		{
			$user.PutEx(3,"targetAddress", @($("smtp:"+$userCn+"@customer.local")))
		}
		if ([int]$userCn.substring(6) -eq 7)
		{
			$user.PutEx(3,"targetAddress", @($("    NOTES:"+$userCn)))
		}
		if ([int]$userCn.substring(6) -eq 9)
		{
			$user.PutEx(3,"targetAddress", @($("smtp:"+$userCn+$domain)))
		}
		if ($userCn.EndsWith("0"))
		{
			$user.PutEx(3,"targetAddress", @($("smtp:"+$userLastCn+$domain)))
		}
	
		# userPrincipalName
		if ([int]$userCn.substring(6) -le 5)
		{
			$user.Put("userPrincipalName", $($userCn+$domain))
		}
		elseif ([int]$userCn.substring(6) -eq 6)
		{
			$user.Put("userPrincipalName", $($userLastCn+$domain))
		}
		elseif ([int]$userCn.substring(6) -eq 9)
		{
			$user.Put("userPrincipalName", $($userCn+"@customer.local"))
		}
		elseif ($userCn.EndsWith("0"))
		{
			$user.Put("userPrincipalName", $("    "+$userCn+"%"+$domain))
		}
		$userLastCn = $userCn

		$user.SetInfo()
	}
}



