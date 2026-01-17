# Connect to SQL Server and handle both Windows Authentication or SQL Server Authentication

# Keep the Connection object as $dbConnection to ensure uniformity
# Function to Open the SQL Server DB Connection
function connectToSQLServer 
{
    
    [CmdletBinding()]
    param (
        # Accept the Server/InstanceName from User
        [Parameter(Mandatory)]
        [string] $serverInstanceName,
        # Accept the Database from User
        [Parameter(Mandatory)]
        [string] $databaseName,
        # Boolean value to specify if the Connection Type is Windows Auth (Integrated Security) or SQL Server (Username/Password)
        [Parameter(Mandatory)]
        [bool] $isWindowsAuth,
        # The below two options are only required for SQL Server Authentication so they are not mandatory
        # Accept the Username for SQL Server Authentication
        [Parameter()]
        [string] $connUserName,
        # Accept the password for SQL Server Authentication
        [Parameter()]
        [string] $connPassword
    )

    try 
    {
        # Create SQL Connection
        $dbConnection = New-Object System.Data.SqlClient.SqlConnection

        # Create the Connection String
        # if isWindowsAuth is set to True use Integrated Security
        if( $isWindowsAuth ) 
        {
            $dbConnection.ConnectionString = "Server=$serverInstanceName;Database=$databaseName;Integrated Security=true"
        }
        else 
        {
            $dbConnection.ConnectionString = "Server=$serverInstanceName;Database=$databaseName;User=$connUserName;Password=$connPassword"
        }

        # Once we have the ConnectionString setup, we Open the DB
        $dbConnection.Open()

        # Open the connection and then Return the Connection Object
        return $dbConnection
    }
    catch 
    {
       Write-Error $_.exception.message     
    }
}

# Function to Close the SQL Server DB Connection
function closeSQLServerDBConnection 
{
    # Only one Mandatory Parameter the SQL DB Connection
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Data.SqlClient.SqlConnection]
        $dbConnection
    )

    try {
        # Close the connection
        $dbConnection.Close()
    }
    catch {
        Write-Error $_.exception.message
    }
}

# Function to invoke SELECT statement on our SQL Server DB
function invokeSQLSelectStmt 
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Data.SqlClient.SqlConnection]
        $dbConnection,
        [Parameter(Mandatory)]
        [string]
        $sqlSelectStmt,
        [Parameter(Mandatory)]
        [string]
        $outGridViewTitle
    )

    try 
    {
        # Create Command Object
        $sqlCommand = $dbConnection.CreateCommand()

        # Set the SQL Select Query
        $sqlCommand.CommandText = "$sqlSelectStmt"

        # Create Adaptor Object
        $sqlDataAdaptor = New-Object System.Data.SqlClient.SqlDataAdapter $sqlCommand

        # Fill up the Adaptor Data into a dataSet
        $sqlDataSet = New-Object System.Data.DataSet

        # The Query Outputs One and we don't want it on the console so we add the return type as void
        [void] $sqlDataAdaptor.Fill( $sqlDataSet )

        $sqlResult = $sqlDataSet.Tables

        foreach( $row in $sqlResult ) {
            $row | Out-GridView -Title $outGridViewTitle
        }
    }
    catch {
        Write-Error $_.exception.message
    }
}

# Function to invoke INSERT statement on our SQL Server DB
function invokeSQLInsertStmt {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Data.SqlClient.SqlConnection]
        $dbConnection,
        [Parameter(Mandatory)]
        [string] 
        $sqlInsertStatement
    )

    try 
    {
        # Create Command Object
        $sqlCommand = $dbConnection.CreateCommand()

        # Set the SQL Select Query
        $sqlCommand.CommandText = "$sqlInsertStatement"

        # Execute the Query returns 1 if successful and 0 if insert is not successfull
        $sqlResult = $sqlCommand.ExecuteNonQuery()

        if( $sqlResult -eq 1 ) 
        {
            Write-Host "`t DB INSERT successful!" -ForegroundColor Green
        }
        else
        {
            Write-Warning "`t DB INSERT Failed!"
        }
           
    }
    catch {
        Write-Error $_.exception.message
    }
}

# Function to invoke UPDATE statement on our SQL Server DB
function invokeSQLUpdateStmt {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Data.SqlClient.SqlConnection]
        $dbConnection,
        [Parameter(Mandatory)]
        [string] 
        $sqlUpdateStatement
    )

    try 
    {
        # Create Command Object
        $sqlCommand = $dbConnection.CreateCommand()

        # Set the SQL Select Query
        $sqlCommand.CommandText = "$sqlUpdateStatement"

        # Execute the Query returns the number of rows updated or 0 if update is not successfull
        $sqlResult = $sqlCommand.ExecuteNonQuery()

        Write-Host "`t Number of Results in our Query = " $sqlResult.Count -ForegroundColor Gray

        if( $sqlResult -ge 1 ) 
        {
            Write-Host "`t DB UPDATE successful!" -ForegroundColor Green
        }
        else
        {
            Write-Warning "`t DB UPDATE Failed!"
        }
           
    }
    catch {
        Write-Error $_.exception.message
    }
}

# Function to invoke DELETE statement on our SQL Server DB
function invokeSQLDeleteStmt {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Data.SqlClient.SqlConnection]
        $dbConnection,
        [Parameter(Mandatory)]
        [string] 
        $sqlDeleteStatement
    )

    try 
    {
        # Create Command Object
        $sqlCommand = $dbConnection.CreateCommand()

        # Set the SQL Select Query
        $sqlCommand.CommandText = "$sqlDeleteStatement"

        # Execute the Query returns the number of rows deleted or 0 if deleted is not successfull
        $sqlResult = $sqlCommand.ExecuteNonQuery()

        Write-Host "`t Number of Results in our Query = " $sqlResult.Count -ForegroundColor Gray

        if( $sqlResult -ge 1 ) 
        {
            Write-Host "`t DB DELETE successful!" -ForegroundColor Green
        }
        else
        {
            Write-Warning "`t DB DELETE Failed!"
        }
           
    }
    catch {
        Write-Error $_.exception.message
    }
}

# Function to return the ID of the Last Inserted Data
function getLastInsertedID
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Data.SqlClient.SqlConnection]
        $dbConnection
    )

    try 
    {
        # Create Command Object
        $sqlCommand = $dbConnection.CreateCommand()

        # Set the SQL Select Query
        $sqlCommand.CommandText = "SELECT @@IDENTITY AS lastVal"

        # Create Adaptor Object
        $sqlDataAdaptor = New-Object System.Data.SqlClient.SqlDataAdapter $sqlCommand

        # Fill up the Adaptor Data into a dataSet
        $sqlDataSet = New-Object System.Data.DataSet

        # The Query Outputs One and we don't want it on the console so we add the return type as void
        [void] $sqlDataAdaptor.Fill( $sqlDataSet )

        $sqlResult = $sqlDataSet.Tables[0]

        $lastID = [int] $sqlResult.Rows[0][0]
        
        # Write-Host "Val : " $lastID " `t Type : " $lastID.GetType()

        # Return the Last Inserted ID Value of the User 
        return $lastID
    }
    catch {
        Write-Error $_.exception.message
    }
}