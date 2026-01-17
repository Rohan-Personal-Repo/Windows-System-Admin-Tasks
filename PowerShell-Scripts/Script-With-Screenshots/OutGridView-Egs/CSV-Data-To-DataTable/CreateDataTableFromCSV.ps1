# Irrespective of the Structure of the CSV File, it will read it and return a DataTable
Import-Module '.\Common-PowerShell-Modules\Read-CSV-File.psm1'

$ADUserDataTable_1 = convertCSVToPSDataTable -csvFilePath '.\Data\AD-UserData.csv'
$ADUserDataTable_1 | Out-GridView -Title "AD User Data 1"

$ADUserDataTable_2 = convertCSVToPSDataTable -csvFilePath '.\Data\AD-Users-WithStatus.csv'
$ADUserDataTable_2 | Out-GridView -Title "AD User Data 2"

$SQLQueryDataTable = convertCSVToPSDataTable -csvFilePath '.\Data\SQL-Query-Output.csv'
$SQLQueryDataTable | Out-GridView -Title "SQL Query Data"

$HR_Dashboard_DataTable = convertCSVToPSDataTable -csvFilePath '.\Data\hr_dashboard_data-final.csv'
$HR_Dashboard_DataTable | Out-GridView -Title "HR Dashboard Data"