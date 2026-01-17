$userNames = @("chandler.bing","monica.geller", "joey.tribbiani", "ross.geller", "phoebe.buffay", "rachel.greene", "gunther")

ForEach( $user in $userNames ){
	Get-ADUser -Identity $user -Properties MemberOf, PasswordLastSet >> userInfo.txt
}

echo "Print User Information:"
cat userInfo.txt

# To run the script just use :  .\scriptName -> Eg .\GetUserInfo.ps1