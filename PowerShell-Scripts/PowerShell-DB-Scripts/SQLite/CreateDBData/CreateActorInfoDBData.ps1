# Import the PSSQlite module
Import-Module PSSQLite -Verbose

# Give the DB Name for the SQLite Connection
$dbName = 'TVActorDB.db'

# Create the Connection object, if DB is not present it will create it for us
$dbConn = New-SQLiteConnection -DataSource $dbName

Write-Host "DB State : " $dbConn.State.ToString() -ForegroundColor Cyan

# Drop the ActorInfo table if it already exists
Invoke-SqliteQuery -Query "DROP TABLE IF EXISTS ActorInfo" -SQLiteConnection $dbConn

# Create the table structure
$tblCreate = "
    CREATE TABLE ActorInfo ( 
        showActorID INTEGER PRIMARY KEY AUTOINCREMENT, 
        actorShowName TEXT, 
        actorRealName TEXT, 
        showName TEXT )"

Invoke-SqliteQuery -Query $tblCreate -SQLiteConnection $dbConn

# View the table information using PRAGMA
Invoke-SqliteQuery -SQLiteConnection $dbConn -Query "PRAGMA table_info(ActorInfo)" | Out-GridView

# This query works irrespective of the DB being present on our System or not
# Invoke-SqliteQuery -Query "queryString" -SQLiteConnection $connectionObj
# If we are sure that the DB is present, otherwise the following would give an error
# Invoke-SqliteQuery -Query "queryString" -DataSource $dataSourceObj

# We will convert the CSV file data into a Data Table
$csvFile = Import-Csv -Path .\TVShowActors.csv
Write-Host "CSV Data : `n" $csvFile -ForegroundColor Cyan
$csvHeaders = $csvFile | Get-Member -MemberType NoteProperty
Write-Host "First Row : " $csvHeaders -ForegroundColor Red
Write-Host "Column Names : " $csvHeaders.Name -ForegroundColor Yellow

# Create a Data Table 
$actorData = New-Object System.Data.DataTable

$actorData.Columns.AddRange( $csvHeaders.Name )

Write-Host "AD: " $actorData.Columns

foreach( $row in $csvFile ) {
    # Create a New  Data Table Row Object
    $data = $actorData.NewRow()
    
    # Fill up the Row object
    $data.actorRealName = $row.actorRealName
    $data.actorShowName = $row.actorShowName
    $data.showName = $row.showName

    # Add the Rows to the Data Table
    $actorData.Rows.Add( $data )
}

# Test the Data Out 
$actorData | Out-GridView

# Bulk Insert the Values into our DB
Invoke-SQLiteBulkCopy -DataTable $actorData -SQLiteConnection $dbConn -Table ActorInfo -Verbose 

# VERBOSE: Running Invoke-SQLiteBulkCopy with ParameterSet 'Connection'.
# VERBOSE: DATATABLE IS System.Data.DataTable with value 
# actorRealName    actorShowName    showName
# -------------    -------------    --------
# Stephen Amell    Oliver Queen     Arrow
# Ioan Gruffudd    Dr. Henry Morgan Forever
# Matthew Perry    Chandler Bing    Friends
# Matt Leblanc     Joey Tribbiani   Friends
# Tim Roth         Cal Lightman     Lie to me
# Kelli Williams   Gillian Foster   Lie to me
# Emily Vancamp    Emily Thorne     Revenge
# Kerry Washington Olivia Pope      Scandal

# VERBOSE: Processing datatable with 8 rows

# Confirm
# Are you sure you want to perform this action?
# Performing the operation "SQL Bulk Copy" on target "8 rows, with BoundParameters
# Key              Value
# ---              -----
# DataTable        {Stephen Amell, Ioan Gruffudd, Matthew Perry, Matt Leblanc...}
# SQLiteConnection System.Data.SQLite.SQLiteConnection
# Table            ActorInfo
# Verbose          True
# "
# [Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"): y

# Verify Data was added to the DB 
# Because of AutoIncrement we also did not need to set the values for the PK
Invoke-SqliteQuery -SQLiteConnection $dbConn -Query "SELECT * FROM ActorInfo ORDER BY showName" | Out-GridView