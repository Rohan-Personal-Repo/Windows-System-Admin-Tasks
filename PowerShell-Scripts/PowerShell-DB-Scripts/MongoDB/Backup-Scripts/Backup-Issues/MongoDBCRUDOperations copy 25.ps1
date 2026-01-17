# --------------------------
# MongoDB Connection
# --------------------------
$connectionString = "mongodb+srv://mongoDBUserName:mongoDBPassword@mongocluster.dev.mongodb.net/"

# Connect to MongoDB
$mongoClient = Connect-Mdbc -ConnectionString $connectionString

# Get Database & Collection
$actorDB = Get-MdbcDatabase -Client $mongoClient -Name "ActorsDatabase"
$actorData = Get-MdbcCollection -Database $actorDB -Name "ActorsData"

# --------------------------
# Helper: Normalize roles to arrays
# --------------------------
function Normalize-Roles {
    param($actors)
    foreach ($a in $actors) {
        if (-not ($a.roles -is [Array])) { 
            $a.roles = @($a.roles) 
        }
    }
    return $actors
}

# --------------------------
# CRUD Functions
# --------------------------

function createActor {
    param($actorName,$heroName,$seriesMovieTitle,$location)
    $doc = @{
        actorName = $actorName
        actorShowName = $heroName
        roles = @(@{ heroName = $heroName; seriesMovieTitle = $seriesMovieTitle; location = $location })
    }
    Add-MdbcData -Collection $actorData -Data $doc
    Write-Host "Inserted $actorName" -ForegroundColor White -BackgroundColor DarkGreen
}

function readOneActor {
    param($actorName)
    $actor = Get-MdbcData -Collection $actorData -Filter @{ actorName = $actorName }
    $actor | Normalize-Roles | Out-GridView -Title "Actor: $actorName"
}

function readAllActors {
    $actors = Get-MdbcData -Collection $actorData
    $actors | Normalize-Roles | Out-GridView -Title "All Actors"
}

function updateMultipleValues {
    param($actorName,$heroName,$seriesMovieTitle,$location)

    $actor = Get-MdbcData -Collection $actorData -Filter @{ actorName = $actorName }
    if ($actor) {
        # Remove _id for safe update
        $updateObj = $actor | Select-Object * -ExcludeProperty _id

        # Normalize roles
        if (-not ($updateObj.roles -is [Array])) { $updateObj.roles = @($updateObj.roles) }

        # Add new role
        $updateObj.roles += @{ heroName = $heroName; seriesMovieTitle = $seriesMovieTitle; location = $location }

        # Update actorShowName
        $updateObj.actorShowName = $heroName

        Update-MdbcData -Collection $actorData -Filter @{ actorName = $actorName } -Update $updateObj
        Write-Host "Updated $actorName with new role $heroName" -ForegroundColor Black -BackgroundColor Yellow
    }
}

function updateSingleValue {
    param($actorName,$newShowName)
    $actor = Get-MdbcData -Collection $actorData -Filter @{ actorName = $actorName }
    if ($actor) {
        $updateObj = $actor | Select-Object * -ExcludeProperty _id
        $updateObj.actorShowName = $newShowName
        Update-MdbcData -Collection $actorData -Filter @{ actorName = $actorName } -Update $updateObj
        Write-Host "$actorName updated to $newShowName" -ForegroundColor White -BackgroundColor DarkMagenta
    }
}

function deleteActorByHero {
    param($heroName)
    $actors = Get-MdbcData -Collection $actorData
    foreach ($a in $actors) {
        $updateObj = $a | Select-Object * -ExcludeProperty _id
        if (-not ($updateObj.roles -is [Array])) { $updateObj.roles = @($updateObj.roles) }
        $updateObj.roles = $updateObj.roles | Where-Object { $_.heroName -ne $heroName }
        Update-MdbcData -Collection $actorData -Filter @{ actorName = $a.actorName } -Update $updateObj
    }
    Write-Host "Deleted role $heroName from all actors" -ForegroundColor White -BackgroundColor DarkRed
}

# --------------------------
# DEMO: CRUD Operations
# --------------------------

# Insert actor
createActor -actorName "Salma Hayek" -heroName "Sonia Kincaid" -seriesMovieTitle "Hitman's Wife's Bodyguard" -location "Ottawa"

# Read specific actor
Write-Host "`n--- Read Kate Beckinsale ---" -ForegroundColor Black -BackgroundColor Cyan
readOneActor -actorName "Kate Beckinsale"

# Read all actors
Write-Host "`n--- Read All Actors ---" -ForegroundColor Black -BackgroundColor Cyan
readAllActors

# Update actor multiple fields
updateMultipleValues -actorName "Matt Leblanc" -heroName "Adam Burns" -seriesMovieTitle "Man with a Plan" -location "Vancouver"

# Update single value
updateSingleValue -actorName "Matthew Perry" -newShowName "Ms. Chanandler Bong"

# Read after updates
Write-Host "`n--- Read Matt Leblanc ---" -ForegroundColor Black -BackgroundColor Cyan
readOneActor -actorName "Matt Leblanc"

Write-Host "`n--- Read Matthew Perry ---" -ForegroundColor Black -BackgroundColor Cyan
readOneActor -actorName "Matthew Perry"

# Delete a role by hero name
deleteActorByHero -heroName "August"

Write-Host "`nDONE!" -ForegroundColor White -BackgroundColor DarkGreen
