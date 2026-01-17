# We use Out-GridView to see a proper GridView of our Data and also Filter Data or Sort Data as required

# Simple O/P Redirection
Get-Service | Out-GridView -Title "Services on my Computer"

# Read CSV Data
$csvFilePath = ".\AD-Users\AD-Users.csv"

$csvData = Import-Csv -Path $csvFilePath -Delimiter ','

$csvData | Out-GridView -Title "Employee Data Read from CSV"

$jsonFilePath = ".\AD-Users\ADUsers2.json"

$jsonData = Get-Content -Path $jsonFilePath | ConvertFrom-Json

$jsonData | Out-GridView -Title "Employee Data Read from JSON"