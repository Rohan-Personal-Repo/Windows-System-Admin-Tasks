$userNames = @("chandler.bing","monica.geller","ross.geller","joey.tribbiani","phoebe.buffay","rachel.greene","gunther")

ForEach( $user in $userNames ){
	 Get-ADUser -Identity $user -Properties MemberOf >> $args[0]
}

echo "Print User Information:"
cat $args[0]

# .\PrintUserInfo.ps1 fileNameToAdd [First for Normal, second was change/retirement]
# $args[0] - First Command Line Argument