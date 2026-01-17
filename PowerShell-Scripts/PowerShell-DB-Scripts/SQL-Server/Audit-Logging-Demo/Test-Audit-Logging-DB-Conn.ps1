# Here we just have to import the Common-DB-AuditLogging module which will internally call Connect-To-SQL-Server-DB module
Import-Module '..\Common-PowerShell-Modules\Common-DB-AuditLogging.psm1' -Force
# - Force is important otherwise any changes we make won't be reflected into our Codebase

# We don't need to send any parameters it connects to AuditLogDB automatically
$dbConn = openConnectionToAuditLogDB
Write-Host "DB Status : " $dbConn.State -ForegroundColor Cyan

# Verify AuditTable Insert 
insertAuditLog -dbConnection $dbConn -dbName 'CompDB' -tableName 'Department' -operation 'DEL' -affectedUserID 125 -dbUserID 'WindowsAdmin' -systemName 'SK-Win2K19' -appName 'Website'

# Verify AuditTable contents
Write-Host "Check out the GridView!" -ForegroundColor Yellow
viewAuditTable -dbConnection $dbConn

# Close the connection
closeConnectionToAuditLogDB -dbConnection $dbConn

Write-Host "DB Status : " $dbConn.State -ForegroundColor Magenta
