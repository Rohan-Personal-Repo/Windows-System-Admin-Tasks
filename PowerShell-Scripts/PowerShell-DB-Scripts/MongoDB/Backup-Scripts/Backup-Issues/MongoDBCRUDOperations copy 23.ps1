# # --------------------------
# # MongoDB connection
# # --------------------------
# $connectionString = "mongodb+srv://mongoDBUserName:mongoDBPassword@mongocluster.dev.mongodb.net/"
# $actorDB = Get-MdbcDatabase -Name "ActorsDatabase"
# $actorData = Get-MdbcCollection -Name "ActorsData" -Database $actorDB

# --------------------------
# MongoDB Connection Setup
# --------------------------
$connectionString = "mongodb+srv://mongoDBUserName:mongoDBPassword@mongocluster.dev.mongodb.net/"

# Create the client
$mongoClient = New-MdbcClient -ConnectionString $connectionString

# Get the database
$actorDB = Get-MdbcDatabase -Client $mongoClient -Name "ActorsDatabase"

# Get the collection
$actorData = Get-MdbcCollection -Database $actorDB -Name "ActorsData"

# Test fetching data
$actors = Get-MdbcData -Collection $actorData
$actors | Out-GridView -Title "All Actors"


# --------------------------
# Helper: Escape quotes
# --------------------------
function Escape-Quotes($str) {
    return $str.Replace('"','\"')
}

# --------------------------
# Normalize roles to arrays
# --------------------------
function Normalize-Roles {
    $actors = Get-MdbcData -Collection $actorData
    foreach ($actor in $actors) {
        if (-not ($actor.roles -is [System.Array])) {
            $rolesArray = @($actor.roles)
            Update-MdbcData -Collection $actorData -Filter @{ _id = $actor._id } -Update @{ '$set' = @{ roles = $rolesArray } }
        }
    }
    Write-Host "Normalized all roles to arrays" -ForegroundColor Green
}

# --------------------------
# Create a new actor
# --------------------------
function createActor {
    param($actorName, $showName, $movie, $location)
    $actorNameSafe = Escape-Quotes $actorName
    $showNameSafe  = Escape-Quotes $showName
    $movieSafe     = Escape-Quotes $movie
    $locationSafe  = Escape-Quotes $location

    $doc = @{
        actorName     = $actorNameSafe
        actorShowName = $showNameSafe
        roles         = @(@{
                            heroName = $showNameSafe
                            seriesMovieTitle = $movieSafe
                            location = $locationSafe
                          })
    }
    Add-MdbcData -Collection $actorData -Document $doc
    Write-Host "Inserted $actorName" -ForegroundColor White -BackgroundColor DarkGreen
}

# --------------------------
# Read one actor
# --------------------------
function readOneActor {
    param($actorName)
    $actorNameSafe = Escape-Quotes $actorName
    $actor = Get-MdbcData -Collection $actorData -Filter @{ actorName = $actorNameSafe }
    $actor | Out-GridView -Title "Actor: $actorName"
}

# --------------------------
# Read all actors
# --------------------------
function readAllActors {
    $actors = Get-MdbcData -Collection $actorData
    $actors | Out-GridView -Title "All Actors"
}

# --------------------------
# Update multiple values (set + push)
# --------------------------
function updateMultipleValues {
    param($actorName, $heroName, $movie, $location)
    $actorNameSafe = Escape-Quotes $actorName
    $heroNameSafe  = Escape-Quotes $heroName
    $movieSafe     = Escape-Quotes $movie
    $locationSafe  = Escape-Quotes $location

    # Ensure roles are arrays
    $actor = Get-MdbcData -Collection $actorData -Filter @{ actorName = $actorNameSafe }
    foreach ($a in $actor) {
        if (-not ($a.roles -is [System.Array])) {
            $rolesArray = @($a.roles)
            Update-MdbcData -Collection $actorData -Filter @{ _id = $a._id } -Update @{ '$set' = @{ roles = $rolesArray } }
        }
    }

    # Update actorShowName and push new role
    $updateDoc = @{
        '$set'  = @{ actorShowName = $heroNameSafe }
        '$push' = @{ roles = @{ heroName = $heroNameSafe; seriesMovieTitle = $movieSafe; location = $locationSafe } }
    }
    Update-MdbcData -Collection $actorData -Filter @{ actorName = $actorNameSafe } -Update $updateDoc
    Write-Host "Updated $actorName with new role $heroName" -ForegroundColor Black -BackgroundColor Yellow
}

# --------------------------
# Update single value (set)
# --------------------------
function updateSingleValue {
    param($actorName, $newShowName)
    $actorNameSafe    = Escape-Quotes $actorName
    $newShowNameSafe  = Escape-Quotes $newShowName

    $updateDoc = @{ '$set' = @{ actorShowName = $newShowNameSafe } }
    Update-MdbcData -Collection $actorData -Filter @{ actorName = $actorNameSafe } -Update $updateDoc

    Write-Host "$actorName updated to $newShowName" -ForegroundColor White -BackgroundColor DarkMagenta
}

# --------------------------
# Delete role by heroName
# --------------------------
function deleteActorByHero {
    param($heroName)
    $heroNameSafe = Escape-Quotes $heroName

    # Ensure roles are arrays
    $actors = Get-MdbcData -Collection $actorData
    foreach ($a in $actors) {
        if (-not ($a.roles -is [System.Array])) {
            $rolesArray = @($a.roles)
            Update-MdbcData -Collection $actorData -Filter @{ _id = $a._id } -Update @{ '$set' = @{ roles = $rolesArray } }
        }
    }

    # Pull role by heroName
    $updateDoc = @{ '$pull' = @{ roles = @{ heroName = $heroNameSafe } } }
    Update-MdbcData -Collection $actorData -Filter @{ } -Update $updateDoc
    Write-Host "Deleted role $heroName from all actors" -ForegroundColor White -BackgroundColor DarkRed
}

# --------------------------
# --------------------------
# Demo Script
# --------------------------
Normalize-Roles

createActor -actorName "Salma Hayek" -showName "Sonia Kincaid" -movie "Hitmans Wifes Bodyguard" -location "Ottawa"

Write-Host "`n--- Read Kate Beckinsale ---" -ForegroundColor Black -BackgroundColor Cyan
readOneActor -actorName "Kate Beckinsale"

Write-Host "`n--- Read All Actors ---" -ForegroundColor Black -BackgroundColor Cyan
readAllActors

updateMultipleValues -actorName "Matt Leblanc" -heroName "Adam Burns" -movie "Man with a Plan" -location "Vancouver"

updateSingleValue -actorName "Matthew Perry" -newShowName "Ms. Chanandler Bong"

Write-Host "`n--- Read Matt Leblanc ---" -ForegroundColor Black -BackgroundColor Cyan
readOneActor -actorName "Matt Leblanc"

Write-Host "`n--- Read Matthew Perry ---" -ForegroundColor Black -BackgroundColor Cyan
readOneActor -actorName "Matthew Perry"

deleteActorByHero -heroName "August"

Write-Host "`nDONE!" -ForegroundColor White -BackgroundColor DarkGreen
