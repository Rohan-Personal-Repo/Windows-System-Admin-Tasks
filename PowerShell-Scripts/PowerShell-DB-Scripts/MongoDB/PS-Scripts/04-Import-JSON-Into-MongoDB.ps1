# Import JSON into MongoDB using Mdbc 7 + PowerShell 7
# Database: ActorsDatabase
# Collection: ActorsData

Import-Module Mdbc -ErrorAction Stop

# 1. Configure paths and connection
# NOTE: Create the Database and Collection using MongoDB Compass
$mongoServer    = $env:MONGO_CONN_STRING
$mongoDatabase  = "ActorsDatabase"
$collectionName = "ActorsData"

if (-not $mongoServer) {
    throw "MONGO_CONN_STRING environment variable is not set. Set it before running this script."
}

# Path to the JSON file we generated earlier
$jsonPath = ".\Data\Movie-Series-Characters.json"

# 2. Connect to MongoDB (Mdbc 7 parameter names)
Connect-Mdbc -ConnectionString $mongoServer `
             -DatabaseName $mongoDatabase `
             -CollectionName $collectionName

Write-Host "Connected to $mongoDatabase.$collectionName" -ForegroundColor Cyan -BackgroundColor Black

# 3. Load JSON (array of documents) into PowerShell objects
if (-not (Test-Path -Path $jsonPath)) {
    Write-Host "JSON file not found at: $jsonPath" -ForegroundColor DarkRed -BackgroundColor Yellow
    return
}

$documents = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json

if (-not $documents) {
    Write-Host "No documents loaded from JSON file (check JSON structure/top-level array)." -ForegroundColor DarkRed -BackgroundColor Yellow
    return
}

Write-Host "Loaded $($documents.Count) documents from JSON." -ForegroundColor Green -BackgroundColor Black

# Optional: show first document structure for sanity check
Write-Host "`n--- Check First document structure for sanity check ---" -ForegroundColor Magenta -BackgroundColor Black
$documents[0] | Format-List | Out-String | Write-Host

# 4. Insert into MongoDB
#    No _id field in input -> MongoDB will auto-generate _id
$documents | Add-MdbcData -Many

# Verify how many docs are now in the collection
$insertedCount = Get-MdbcData -As PS | Measure-Object | Select-Object -ExpandProperty Count
Write-Host "Collection now contains $insertedCount documents in $mongoDatabase.$collectionName" -ForegroundColor Cyan -BackgroundColor Black

# 5. Quick view of inserted data in Out-GridView
$actors = Get-MdbcData -As PS

if (-not $actors) {
    Write-Host "No actors found."
    return
}

$rows = foreach ($a in $actors) {
    foreach ($r in $a.roles) {
        [PSCustomObject]@{
            ActorName        = $a.heroName
            RoleName         = $r.roleName
            SeriesMovieTitle = $r.seriesMovieTitle
            Location         = $r.Address
        }
    }
}

$rows | Out-GridView -Title "All Actors and Roles"