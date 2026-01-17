$csvFile = Import-Csv ".\AD-Users-WithStatus.csv"

# Create the Data Table
$tblColumnNames = @( "FirstName", "LastName", "FullName", "UserName","EmailID", "UserGroup", "Country", "IsEnabled" )

# Create a Data Table 
$userData = New-Object System.Data.DataTable

$userData.Columns.AddRange( $tblColumnNames )

Write-Host "AD: " $userData.Columns

foreach($line in $csvFile)  {
	
	$fullName = $line.Name
	$userName = $line.SamAccountName
	$emailID = $line.UserPrincipalName
	$firstName = $line.FirstName
	$lastName = $line.LastName

	Write-Host "Name : " $fullName
	Write-Host "First Name : " $firstName
	Write-Host "Last Name : " $lastName
	Write-Host "UserName : " $userName
	Write-Host "Email-ID : " $emailID
	
    #Convert Enabled from String to Boolean
	$isEnabled = [System.Convert]::ToBoolean($line.Enabled)
	Write-Host "isEnabled : " $isEnabled

	$groupPath = $line.MemberOf -split ","
	
	Write-Host "Group Path : " $groupPath 

	$groupName = $($groupPath[0] -split "=")[1]
	$country = $($groupPath[1] -split "=")[1]
	$appName = $($groupPath[2] -split "=")[1]

	Write-Host "Group Name : " $groupName 
	Write-Host "Country : " $country
	Write-Host "App: " $appName "`n"
		
    # Just a Line Break
	Write-Host "`t ---------------------------------------"

    # Create a New  Data Table Row Object
    $row = $userData.NewRow()
    
    # Fill up the Row object
    $row.FirstName = $firstName
    $row.LastName = $lastName
    $row.FullName = $fullName
    $row.UserName = $userName
    $row.EmailID = $emailID
    $row.UserGroup = $groupName
    $row.Country = $country
    $row.IsEnabled = $isEnabled

    # Add the Rows to the Data Table
    $userData.Rows.Add( $row )
}

# Test the Data Out 
$userData | Out-GridView

# Create a CSV File of the Data
$userData | Export-Csv -Path '.\AD-UserData.csv' -NoTypeInformation