# Lets Add the Module we created before
Import-Module '.\PS-DB-Scripts\SQL-Server\SQL-CRUD-Operations\Common-PowerShell-Modules\Connect-To-SQL-Server-DB.psm1' -Force

$sqlServerAuthConn = connectToSQLServer -serverInstanceName "dbServerName" -databaseName "ADUserDB" -isWindowsAuth $false -connUserName "SQLAdmin" -connPassword "SQLAdmin"

Write-Host "DB Status before : " $sqlServerAuthConn.State -ForegroundColor Cyan

# R - Read part of CRUD - SELECT
# Let's Select the Data from the DB - Since we have it in the Module it's really easy to just change the parameters
# invokeSQLSelectStmt -dbConnection $sqlServerAuthConn -sqlSelectStmt "SELECT * FROM EmpCountry" -outGridViewTitle "Country Data"

# invokeSQLSelectStmt -dbConnection $sqlServerAuthConn -sqlSelectStmt "SELECT * FROM EmpUserGroup" -outGridViewTitle "User Group Data"

# invokeSQLSelectStmt -dbConnection $sqlServerAuthConn -sqlSelectStmt "SELECT * FROM Employees" -outGridViewTitle "Emp Data"

# We created a separate function because after every Insert, Update or Delete we can just call this function with different headings
function displayEmpData 
{
    param (
        [Parameter(Mandatory)]
        [string] $gridViewTitle
    )

    invokeSQLSelectStmt -dbConnection $sqlServerAuthConn -sqlSelectStmt "SELECT empFirstName,empLastName,empFullName,empUserName,empEmailId, empUserGroupName,empCountryName, empIsEnabled = CASE empIsEnabled WHEN '1' THEN 'True' WHEN '0' THEN 'False' END FROM Employees, EmpCountry, EmpUserGroup WHERE Employees.empUsrGrp = EmpUserGroup.empUserGroupId AND Employees.empCountry = EmpCountry.empCountryId" -outGridViewTitle $gridViewTitle
}

displayEmpData -gridViewTitle "Emp Country and Group Data"

# C - Create part of CRUD - INSERT a new record
invokeSQLInsertStmt -dbConnection $sqlServerAuthConn -sqlInsertStatement "INSERT INTO Employees( empFirstName,empLastName,empFullName,empUserName,empEmailId,empIsEnabled,empUsrGrp,empCountry ) VALUES ( 'Janice', 'Litman-Goralnik', 'Janice Felula Litman-Goralnik', 'janice.f.litman', 'janice.f.litman@easysystems.in', 0, 260, 115 )"
displayEmpData -gridViewTitle "Emp Data After Insert!"

# Get the Last Inserted ID Value of the User to be passed onto the Update and Delete statement
$lastID = getLastInsertedID -dbConnection $sqlServerAuthConn

# U - Update part of CRUD - UPDATE an existing record
invokeSQLUpdateStmt -dbConnection $sqlServerAuthConn -sqlUpdateStatement "UPDATE Employees SET empCountry = 100 WHERE empId = $lastID"
displayEmpData -gridViewTitle "Emp Data After Update!"

# D - Delete part of CRUD - DELETE an existing record
invokeSQLDeleteStmt -dbConnection $sqlServerAuthConn -sqlDeleteStatement "DELETE FROM Employees WHERE empId = $lastID"
displayEmpData -gridViewTitle "Emp Data After Delete!"

closeSQLServerDBConnection -dbConnection $sqlServerAuthConn

Write-Host "DB Status after : " $sqlServerAuthConn.State -ForegroundColor Magenta