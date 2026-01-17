# Read and Print CSV Files

$csvFile = Import-Csv ".\AD-Users-WithStatus.csv"

foreach($line in $csvFile){
	
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

	# Create the Security Group in the appropriate OU
	New-ADGroup -Name $groupName -GroupCategory "Security" -GroupScope "Global" -Path $OUPath
	
	# Create the User in the appropriate OU
	New-ADUser -Name $firstName -GivenName $firstName -Surname $lastName -DisplayName $fullName -SamAccountName $userName -UserPrincipalName $emailID -Path $OUPath -AccountPassword (ConvertTo-SecureString -AsPlainText "Pass@12345" -Force) -ChangePasswordAtLogon $True -Enabled $isEnabled

	# Add User to the Security Group
	Add-ADGroupMember -Identity $groupName -Members $userName
	
	# Get User Information:
	Get-ADUser -Identity $userName -Properties MemberOf

	# Just a Line Break
	Write-Host "`t ---------------------------------------"
}