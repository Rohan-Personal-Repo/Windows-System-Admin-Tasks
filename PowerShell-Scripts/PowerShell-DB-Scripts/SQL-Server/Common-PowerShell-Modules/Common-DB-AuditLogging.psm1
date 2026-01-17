# This Module will internally call our Connect-To-SQL-Server-DB Module we created earlier
Import-Module '.\Common-PowerShell-Modules\Connect-To-SQL-Server-DB.psm1' -Force

# Function to Connect to Our AuditLogging DB
function openConnectionToAuditLogDB
{
# We don't need any Params, we will internally create the Connection to the AuditLogDB since AuditLogging is common for all DBs
    [CmdletBinding()]
    param ()

    try 
    {
        # This is going to be fixed so we don't accept any Input from User
        $dbConnection = connectToSQLServer -serverInstanceName "dbServerName" -databaseName "AuditLogDB" -isWindowsAuth $true

        # Write-Host "DB Status : " $dbConnection.State -ForegroundColor Green

        return $dbConnection
    }
    catch 
    {
        Write-Error $_.exception.message
    }

}

function closeConnectionToAuditLogDB
{

    # Here we need to pass the Connection Object
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Data.SqlClient.SqlConnection]
        $dbConnection
    )
    try 
    {
        closeSQLServerDBConnection -dbConnection $dbConnection
    }
    catch 
    {
        Write-Error $_.exception.message
    }

}

function viewAuditTable 
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Data.SqlClient.SqlConnection]
        $dbConnection
    )

    try 
    {
        invokeSQLSelectStmt -dbConnection $dbConnection -sqlSelectStmt "SELECT * FROM AuditTable ORDER BY auditEntryDate DESC" -outGridViewTitle "Audit Log Data!"
    }
    catch 
    {
        Write-Error $_.exception.message
    }
}

function insertAuditLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Data.SqlClient.SqlConnection]
        $dbConnection,
        [Parameter(Mandatory)]
        [string] $dbName,
        [Parameter(Mandatory)]
        [string] $tableName,
        # Ensure operation would be insert, update or delete
        [Parameter(Mandatory)]
        [ ValidateSet('INS','UPD','DEL') ]
        [string] $operation,
        [Parameter(Mandatory)]
        [string] $affectedUserID,
        [Parameter(Mandatory)]
        [string] $dbUserID,
        [Parameter(Mandatory)]
        [string] $systemName,
        [Parameter(Mandatory)]
        [string] $appName
    )

    try 
    {
        # Write-Host "$tableName, $operation, $affectedUserID,$dbUserID,$systemName,$appName"

        $sqlQuery = "INSERT INTO AuditTable (dbName, tableName,operation,affectedUserId,initiatedByDBUser,systemName,appName) VALUES ('$dbName','$tableName', '$operation', $affectedUserID,'$dbUserID','$systemName','$appName')"
        # Write-Host "Query : " $sqlQuery
        invokeSQLInsertStmt -dbConnection $dbConnection -sqlInsertStatement $sqlQuery
    }
    catch {
        Write-Error $_.exception.message
    }
}