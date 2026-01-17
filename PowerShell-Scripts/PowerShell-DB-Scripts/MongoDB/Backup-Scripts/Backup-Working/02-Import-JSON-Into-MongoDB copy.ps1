# Import JSON into MongoDB using Mdbc 7 + PowerShell 7
# Database: ActorsDatabase
# Collection: ActorsData

Import-Module Mdbc -ErrorAction Stop

# 1. Configure paths and connection
$mongoServer    = "mongodb+srv://mongoDBUserName:mongoDBPassword@mongocluster.dev.mongodb.net/"
$mongoDatabase  = "ActorsDatabase"
$collectionName = "ActorsData"

# Path to the JSON file you generated earlier
# Use FULL PATH or ensure this relative path is correct
$jsonPath = ".\Data\Movie-Series-Characters.json"

# 2. Connect to MongoDB (correct parameter names)
Connect-Mdbc -ConnectionString $mongoServer `
             -DatabaseName $mongoDatabase `
             -CollectionName $collectionName

# 3. Load JSON (array of documents) into PowerShell objects
$documents = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json

# 4. Insert into MongoDB (Mongo auto-generates _id)
if ($documents) {
    $documents | Add-MdbcData
    Write-Host "Imported $($documents.Count) documents into $mongoDatabase.$collectionName" -ForegroundColor Cyan -BackgroundColor Black
}
else {
    Write-Host "No documents loaded from JSON file: $jsonPath" -ForegroundColor DarkRed -BackgroundColor Yellow 
}

# 5. Quick view of inserted data in Out-GridView

# Read back documents as PowerShell objects
$actors = Get-MdbcData -As PS

# Flatten roles so each row is one role with actor + role columns
$flattenedActors = foreach ($actor in $actors) {

    $roles = if ($actor.roles -is [System.Collections.IEnumerable] -and
                 -not ($actor.roles -is [string])) {
                 $actor.roles
             } else {
                 @($actor.roles)
             }

    foreach ($role in $roles) {
        [PSCustomObject]@{
            ActorName        = $actor.actorName
            HeroName         = $role.heroName
            SeriesMovieTitle = $role.seriesMovieTitle
            Location         = $role.location
        }
    }
}

$flattenedActors | Out-GridView -Title "ActorsDatabase.ActorsData – Imported Actors and Roles"