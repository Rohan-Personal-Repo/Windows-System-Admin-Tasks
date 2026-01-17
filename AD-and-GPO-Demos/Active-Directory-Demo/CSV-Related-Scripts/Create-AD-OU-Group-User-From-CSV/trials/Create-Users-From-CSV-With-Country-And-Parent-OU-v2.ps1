# Read and Print CSV Files

$csvFile = Import-Csv ".\AD-Users-WithStatus.csv"

# Check if Parent OU exists
try
{
	Get-ADOrganizationalUnit -Identity "OU=NP-Chat-App,DC=easysystems,DC=in" | Out-Null
	Write-Host "OU 'OU=NP-Chat-App,DC=easysystems,DC=in' already exists do not re-create!"
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
{
	# Create the Parent OU
	Write-Host "Creating new OU 'OU=NP-Chat-App,DC=easysystems,DC=in'"
	# New-ADOrganizationalUnit -Name "NP-Chat-App" -Path "DC=easysystems,DC=in" -ProtectedFromAccidentalDeletion $True
}

foreach($line in $csvFile)
{
	
	$fullName = $line.Name
	$userName = $line.SamAccountName
	$emailID = $line.UserPrincipalName
	$firstName = $line.FirstName
	$lastName = $line.LastName

	Write-Host "Name : " $fullName
	Write-Host "F-Name : " $firstName
	Write-Host "L-Name : " $lastName
	Write-Host "UserName : " $userName
	Write-Host "Email-ID : " $emailID
	
	$groupPath = $line.MemberOf -split ","
	
	Write-Host "Group Path : " $groupPath 

	$groupName = $($groupPath[0] -split "=")[1]
	$country = $($groupPath[1] -split "=")[1]
	$appName = $($groupPath[2] -split "=")[1]

	Write-Host "Group Name : " $groupName 
	Write-Host "Country : " $country
	Write-Host "App: " $appName "`n"
	
	#Convert Enabled from String to Boolean
	$isEnabled = [System.Convert]::ToBoolean($line.Enabled)
	
	# Remove Group and then Join Together to get OU Path
	$OUPath = $($groupPath[1],$groupPath[2],$groupPath[3],$groupPath[4]) -join ","
	Write-Host "OU: " $OUPath  "`n"

	# Check if the OU exists
    	try {
        	Get-ADOrganizationalUnit -Identity $OUPath | Out-Null
        	Write-Host "OU '$OUPath' already exists do not re-create!"
    	}
    	catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
		# Create the appropriate Country OU
		Write-Host "Creating new OU '$OUPath'"
		New-ADOrganizationalUnit -Name $country -Path "OU=NP-Chat-App,DC=easysystems,DC=in" -ProtectedFromAccidentalDeletion $False
    	}

	# Check if the Security Group Exists
	$ifGroupExists = Get-ADGroup -Filter {Name -eq $groupName} -ErrorAction Stop
	# This does not raise any exception so we just do a Null Check here
	if ( $ifGroupExists ) {
        	Write-Host "Security group '$groupName' exists."
    	} else {
        	# Create the Security Group in the appropriate OU
		New-ADGroup -Name $groupName -GroupCategory “Security” -GroupScope “Global” -Path $OUPath
    	}

	# Check if the User Exists
	$ifUserExists = Get-ADUser -Filter {SamAccountName -eq $userName} -ErrorAction Stop
	# This does not raise any exception so we just do a Null Check here
	if ($user) {
    		Write-Host "User '$userName' already exists."
	} else {
		Write-Host "User '$userName' does not exist."
		
		# Create the User in the appropriate OU
		New-ADUser -Name $firstName -GivenName $firstName -Surname $lastName -DisplayName $fullName -SamAccountName $userName -UserPrincipalName $emailID -Path $OUPath -AccountPassword (ConvertTo-SecureString -AsPlainText "Pass@12345" -Force) -ChangePasswordAtLogon $True -Enabled $isEnabled

	}
	
	$userDetails = 	Get-ADUser -Identity $userName -Properties MemberOf

	Write-Host "MO : " $userDetails.MemberOf
	Write-Host "Condition : " $userDetails.MemberOf -contains $OUPath

	# Check if User is Already a member of the specified Group 
	if( $userDetails.MemberOf -contains $OUPath ) {
		Write-Host "'$userName' is already a member of $groupName."
	} else {
		Write-Host "'$userName' is not a member of $groupName."
		# Add User to the Security Group
		Add-ADGroupMember -Identity $groupName -Members $userName		
	}

	# Print User Information:
	Write-Host "`n User Details : "
	Get-ADUser -Identity $userName -Properties MemberOf
}