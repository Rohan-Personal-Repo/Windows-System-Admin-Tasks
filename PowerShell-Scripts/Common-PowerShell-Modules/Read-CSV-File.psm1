# Read a CSV File and Return the Data

function convertCSVToPSDataTable 
{
    
    [CmdletBinding()]
    param (
        # Accept the CSV File Path from User
        [Parameter(Mandatory)]
        [string] $csvFilePath
    )

    try 
    {
        # Check if Path Exists 
        if( Test-Path $csvFilePath -PathType Leaf){
            # It exists lets import it
            $csvFile = Import-Csv -Path $csvFilePath
            # Separate the Column Header Values
            $csvHeaders = $csvFile | Get-Member -MemberType NoteProperty

            $csvDataTable = New-Object System.Data.DataTable
            
            $columnNames = $csvHeaders.Name

            # Add Column Names to the Data Table
            $csvDataTable.Columns.AddRange( $columnNames )

            foreach( $row in $csvFile ) 
            {
                # Create a New  Data Table Row Object
                $data = $csvDataTable.NewRow()

                  # Fill up the Row object
                # Loop through each column Name and Add them to the Data Table
                foreach( $col in $columnNames )
                {
                    # Navigate through each row and grab values from each column
                    $data.$col = $row.$col
                }

                # Add the Rows to the Data Table
                $csvDataTable.Rows.Add( $data )
            }
            
            # Return the Data Table to the User 
            return $csvDataTable
        }
        else {
            # It does not exist throw a FileNotFoundException
            throw [System.IO.FileNotFoundException] "$csvFilePath does not exist."
        }
    }
    catch 
    {
       Write-Error $_.exception.message     
    }
}