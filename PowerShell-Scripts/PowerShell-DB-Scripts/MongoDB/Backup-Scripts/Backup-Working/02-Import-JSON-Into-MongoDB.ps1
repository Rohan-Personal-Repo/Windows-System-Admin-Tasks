# Import JSON into MongoDB using Mdbc 7 + PowerShell 7
# Database: ActorsDatabase
# Collection: ActorsData

# Import the Module and Stop if any Error Occurs
Import-Module Mdbc -ErrorAction Stop

# 1. Configure paths and connection
$mongoServer    = "mongodb+srv://mongoDBUserName:mongoDBPassword@mongocluster.dev.mongodb.net/"
$mongoDatabase  = "ActorsDatabase"
$collectionName = "ActorsData"

# Path to the JSON file you generated earlier
$jsonPath = ".\Data\Movie-Series-Characters.json"

# 2. Connect to MongoDB
Connect-Mdbc -ConnectionString $mongoServer `
             -DatabaseName $mongoDatabase `
             -CollectionName $collectionName

# 3. Load JSON (array of documents) into PowerShell objects
$documents = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json

# 4. Insert into MongoDB
#    No -NewId, no _id field in input -> MongoDB will auto-generate _id
$documents | Add-MdbcData

Write-Host "Imported $($documents.Count) documents into $mongoDatabase.$collectionName" -ForegroundColor Cyan -BackgroundColor Black

# 5. Quick view of inserted data in Out-GridView

# Read back documents as PowerShell objects
$actors = Get-MdbcData -As PS

# Flatten roles so each row is one role with actor + role columns
$flattenedActors = foreach ($actor in $actors) {

    # Ensure roles is treated as an array
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

# Show in grid
$flattenedActors | Out-GridView -Title "ActorsDatabase.ActorsData – Imported Actors and Roles"