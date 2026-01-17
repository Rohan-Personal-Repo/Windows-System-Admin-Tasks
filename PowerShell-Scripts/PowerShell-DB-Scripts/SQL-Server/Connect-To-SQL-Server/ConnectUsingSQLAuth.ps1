# Create SQL Connection
$sqlConn = New-Object System.Data.SqlClient.SqlConnection

# Create the Connection String
# I don't have an Instance Name Setup so ignore it and with SQL Server Authentication I need to specify the newly created User Credentials
$sqlConn.ConnectionString = "Server=dbServerName;Database=ADUserDB;User=SQLAdmin;Password=SQLAdmin"

# Open the Connection
$sqlConn.Open()

Write-Host "DB Status : " $sqlConn.State -ForegroundColor Cyan

Write-Host "DB Name : " $sqlConn.Database -ForegroundColor Magenta

Write-Host "Server Name : " $sqlConn.DataSource -ForegroundColor Yellow

# Unique GUID Created for every TimeOut Duration
Write-Host "Connection ID : " $sqlConn.ClientConnectionId -ForegroundColor Green

Write-Host "TimeOut : " $sqlConn.ConnectionTimeout

Write-Host "Server Version : " $sqlConn.ServerVersion -ForegroundColor Blue

# Close the Connection
$sqlConn.Close()

Write-Host "DB Status : " $sqlConn.State -ForegroundColor Red