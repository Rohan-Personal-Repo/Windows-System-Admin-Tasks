# Lets Add the Module we created before
Import-Module '..\Common-PowerShell-Modules\Connect-To-SQL-Server-DB.psm1' -Force

$sqlServerAuthConn = connectToSQLServer -serverInstanceName "dbServerName" -databaseName "ADUserDB" -isWindowsAuth $false -connUserName "SQLAdmin" -connPassword "SQLAdmin"

Write-Host "SS DB Status : " $sqlServerAuthConn.State -ForegroundColor Cyan

closeSQLServerDBConnection -dbConnection $sqlServerAuthConn

Write-Host "SS DB Status : " $sqlServerAuthConn.State -ForegroundColor Magenta

$windowsAuthConn = connectToSQLServer -serverInstanceName "dbServerName" -databaseName "ADUserDB" -isWindowsAuth $true

# Open the Connection
Write-Host "WA DB Status : " $windowsAuthConn.State -ForegroundColor Cyan

closeSQLServerDBConnection -dbConnection $windowsAuthConn

Write-Host "WA DB Status : " $windowsAuthConn.State -ForegroundColor Magenta

# Let's Test Wrong Credentials
$sqlServerAuthConn = connectToSQLServer -serverInstanceName "dbServerName" -databaseName "ADUserDB" -isWindowsAuth $false -connUserName "SQLAdmin1" -connPassword "SQLAdmin1"
# Gives an Error - connectToSQLServer : Exception calling "Open" with "0" argument(s): "Login failed for user 'SQLAdmin1'."