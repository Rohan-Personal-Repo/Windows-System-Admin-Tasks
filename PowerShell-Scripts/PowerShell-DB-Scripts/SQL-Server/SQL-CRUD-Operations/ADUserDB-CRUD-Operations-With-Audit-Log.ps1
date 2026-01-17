# Lets Add the Module we created before
# Here we just have to import the Common-DB-AuditLogging module which will internally call Connect-To-SQL-Server-DB module
Import-Module '..\Common-PowerShell-Modules\Common-DB-AuditLogging.psm1' -Force

$sqlServerAuthConn = connectToSQLServer -serverInstanceName "dbServerName" -databaseName "ADUserDB" -isWindowsAuth $false -connUserName "SQLAdmin" -connPassword "SQLAdmin"

Write-Host "ADUserDB Status before : " $sqlServerAuthConn.State -ForegroundColor Cyan

$dbConn = openConnectionToAuditLogDB
Write-Host "AuditLogDB Status : " $dbConn.State -ForegroundColor Cyan

# R - Read part of CRUD - SELECT

# We created a separate function because after every Insert, Update or Delete we can just call this function with different headings
function displayEmpData 
{
    param (
        [Parameter(Mandatory)]
        [string] $gridViewTitle
    )

    invokeSQLSelectStmt -dbConnection $sqlServerAuthConn -sqlSelectStmt "SELECT empFirstName,empLastName,empFullName,empUserName,empEmailId, empUserGroupName,empCountryName, empIsEnabled = CASE empIsEnabled WHEN '1' THEN 'True' WHEN '0' THEN 'False' END FROM Employees, EmpCountry, EmpUserGroup WHERE Employees.empUsrGrp = EmpUserGroup.empUserGroupId AND Employees.empCountry = EmpCountry.empCountryId" -outGridViewTitle $gridViewTitle
}

displayEmpData -gridViewTitle "Emp Country and Group Data Initially"

# C - Create part of CRUD - INSERT a new record
invokeSQLInsertStmt -dbConnection $sqlServerAuthConn -sqlInsertStatement "INSERT INTO Employees( empFirstName,empLastName,empFullName,empUserName,empEmailId,empIsEnabled,empUsrGrp,empCountry ) VALUES ( 'Janice', 'Litman-Goralnik', 'Janice Felula Litman-Goralnik', 'janice.f.litman', 'janice.f.litman@easysystems.in', 0, 260, 115 )"
displayEmpData -gridViewTitle "Emp Data After Insert!"

# Get the Last Inserted ID Value of the User to be passed onto the Update and Delete statement
$lastID = getLastInsertedID -dbConnection $sqlServerAuthConn

# Insert Data into Audit Log
insertAuditLog -dbConnection $dbConn -dbName 'ADUserDB' -tableName 'Employees' -operation 'INS' -affectedUserID $lastID -dbUserID 'WindowsAdmin' -systemName 'SK-Win2K22' -appName 'AD-App'

# U - Update part of CRUD - UPDATE an existing record
invokeSQLUpdateStmt -dbConnection $sqlServerAuthConn -sqlUpdateStatement "UPDATE Employees SET empCountry = 100 WHERE empId = $lastID"
displayEmpData -gridViewTitle "Emp Data After Update!"

# Insert Data into Audit Log
insertAuditLog -dbConnection $dbConn -dbName 'ADUserDB' -tableName 'Employees' -operation 'UPD' -affectedUserID $lastID -dbUserID 'WindowsAdmin' -systemName 'SK-Win2K19' -appName 'UMG-App'

# D - Delete part of CRUD - DELETE an existing record
invokeSQLDeleteStmt -dbConnection $sqlServerAuthConn -sqlDeleteStatement "DELETE FROM Employees WHERE empId = $lastID"
displayEmpData -gridViewTitle "Emp Data After Delete!"

# Insert Data into Audit Log
insertAuditLog -dbConnection $dbConn -dbName 'ADUserDB' -tableName 'Employees' -operation 'DEL' -affectedUserID $lastID -dbUserID 'WindowsAdmin' -systemName 'CA-Win2K19' -appName 'SSMS'

closeSQLServerDBConnection -dbConnection $sqlServerAuthConn

Write-Host "ADUserDB Status after : " $sqlServerAuthConn.State -ForegroundColor Magenta

# Verify AuditTable contents
Write-Host "Check out the GridView!" -ForegroundColor Yellow
viewAuditTable -dbConnection $dbConn

# Close the connection
closeConnectionToAuditLogDB -dbConnection $dbConn

Write-Host "AuditLogDB Status : " $dbConn.State -ForegroundColor Magenta
