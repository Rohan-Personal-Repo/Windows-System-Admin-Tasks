# SQLServer Pre-integrated with PowerShell (via SqlServer module) since it's a Microsoft product so we didn't have to install any drivers
# Create SQL Connection
$sqlConn = New-Object System.Data.SqlClient.SqlConnection

# Create the Connection String
# I don't have an Instance Name Setup so I ignore it and Windows Authentication on the Same User so Integrated Security
$sqlConn.ConnectionString = "Server=dbServerName;Database=CompDB;Integrated Security=true"

# Open the Connection
$sqlConn.Open()

# Create Command Object
$sqlCommand = $sqlConn.CreateCommand()

# Check a Select Command
$sqlCommand.CommandText = "SELECT CONCAT( empFirstName, ' ', empLastName ) AS empName, CONCAT( empCity, ' , ', empCountry ) AS empLocation, empBirthDate, empHireDate, empJobTitle, empEmailId, empSalary, deptName, deptType FROM Employee JOIN Department ON Employee.empDept = Department.deptId ORDER BY empSalary DESC"

# Create Adaptor Object
$sqlDataAdaptor = New-Object System.Data.SqlClient.SqlDataAdapter $sqlCommand

# Fill up the Adaptor Data into a dataSet
$sqlDataSet = New-Object System.Data.DataSet
$sqlDataAdaptor.Fill( $sqlDataSet )

$sqlResult = $sqlDataSet.Tables

Write-Host "Number of Results in our Query = " $sqlResult.Count

foreach( $row in $sqlResult ) {
    $row | Out-GridView -Title "Employee Department Data"
}

# Close the Connection
$sqlConn.Close()