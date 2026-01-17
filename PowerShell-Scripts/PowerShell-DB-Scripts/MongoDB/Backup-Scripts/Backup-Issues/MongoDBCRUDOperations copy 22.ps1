# --------------------------
# MongoDB connection
# --------------------------
$connectionString = "mongodb+srv://mongoDBUserName:mongoDBPassword@mongocluster.dev.mongodb.net/"
Connect-Mdbc -ConnectionString $connectionString

$actorDB = Get-MdbcDatabase -Name "ActorsDatabase"
$actorData = Get-MdbcCollection -Name "ActorsData" -Database $actorDB

# --------------------------
# Helper: Escape quotes
# --------------------------
function Escape-Quotes($str) {
    return $str.Replace('"','\"')
}

# --------------------------
# Normalize all roles to arrays
# --------------------------
function Normalize-Roles {
    $actors = Get-MdbcData -Collection $actorData
    foreach ($actor in $actors) {
        if (-not ($actor.roles -is [System.Array])) {
            $rolesArray = @($actor.roles)
            Update-MdbcData -Collection $actorData -Filter @{_id = $actor._id} -Set @{roles = $rolesArray}
        }
    }
    Write-Host "Normalized all roles to arrays" -ForegroundColor Green
}

# --------------------------
# Create actor
# --------------------------
function createActor {
    param($actorName,$showName,$movie,$location)
    $actorNameSafe = Escape-Quotes $actorName
    $showNameSafe  = Escape-Quotes $showName
    $movieSafe     = Escape-Quotes $movie
    $locationSafe  = Escape-Quotes $location

    $doc = @{
        actorName = $actorNameSafe
        actorShowName = $showNameSafe
        roles = @(@{ heroName = $showNameSafe; seriesMovieTitle = $movieSafe; location = $locationSafe })
    }

    Add-MdbcData -Collection $actorData -Document $doc
    Write-Host "Inserted $actorName" -ForegroundColor White -BackgroundColor DarkGreen
}

# --------------------------
# Flatten roles for display
# --------------------------
function Flatten-Roles($actors) {
    $flattened = foreach ($a in $actors) {
        foreach ($role in @($a.roles)) {
            [PSCustomObject]@{
                ActorName        = $a.actorName
                ActorShowName    = if ($a.actorShowName) { $a.actorShowName } else { "" }
                HeroName         = $role.heroName
                SeriesMovieTitle = $role.seriesMovieTitle
                Location         = $role.location
            }
        }
    }
    return $flattened
}

# --------------------------
# Read one actor
# --------------------------
function readOneActor {
    param($actorName)
    $actorNameSafe = Escape-Quotes $actorName
    $actor = Get-MdbcData -Collection $actorData -Filter @{ actorName = $actorNameSafe }
    Flatten-Roles $actor | Out-GridView -Title "Actor: $actorName"
}

# --------------------------
# Read all actors
# --------------------------
function readAllActors {
    $actors = Get-MdbcData -Collection $actorData
    Flatten-Roles $actors | Out-GridView -Title "All Actors"
}

# --------------------------
# Update multiple values (set + push)
# --------------------------
function updateMultipleValues {
    param($actorName,$heroName,$movie,$location)
    $actorNameSafe = Escape-Quotes $actorName
    $heroNameSafe  = Escape-Quotes $heroName
    $movieSafe     = Escape-Quotes $movie
    $locationSafe  = Escape-Quotes $location

    # Ensure actor roles is array
    $actor = Get-MdbcData -Collection $actorData -Filter @{ actorName = $actorNameSafe }
    foreach ($a in $actor) {
        if (-not ($a.roles -is [System.Array])) {
            $rolesArray = @($a.roles)
            Update-MdbcData -Collection $actorData -Filter @{ _id = $a._id } -Set @{ roles = $rolesArray }
        }
    }

    # Set actorShowName and push new role
    Update-MdbcData -Collection $actorData -Filter @{ actorName = $actorNameSafe } `
        -Set @{ actorShowName = $heroNameSafe } `
        -Push @{ roles = @{ heroName = $heroNameSafe; seriesMovieTitle = $movieSafe; location = $locationSafe } }

    Write-Host "Updated $actorName with new role $heroName" -ForegroundColor Black -BackgroundColor Yellow
}

# --------------------------
# Update single value (set)
# --------------------------
function updateSingleValue {
    param($actorName,$newShowName)
    $actorNameSafe = Escape-Quotes $actorName
    $newShowNameSafe = Escape-Quotes $newShowName

    Update-MdbcData -Collection $actorData -Filter @{ actorName = $actorNameSafe } -Set @{ actorShowName = $newShowNameSafe }
    Write-Host "$actorName updated to $newShowName" -ForegroundColor White -BackgroundColor DarkMagenta
}

# --------------------------
# Delete role by heroName (pull)
# --------------------------
function deleteActorByHero {
    param($heroName)
    $heroNameSafe = Escape-Quotes $heroName

    # Ensure all roles are arrays before pulling
    $actors = Get-MdbcData -Collection $actorData
    foreach ($a in $actors) {
        if (-not ($a.roles -is [System.Array])) {
            $rolesArray = @($a.roles)
            Update-MdbcData -Collection $actorData -Filter @{ _id = $a._id } -Set @{ roles = $rolesArray }
        }
    }

    # Pull the role
    Update-MdbcData -Collection $actorData -Filter @{} -Pull @{ roles = @{ heroName = $heroNameSafe } }
    Write-Host "Deleted role $heroName from all actors" -ForegroundColor White -BackgroundColor DarkRed
}

# --------------------------
# Demo / Execution
# --------------------------

# Normalize roles first
Normalize-Roles

# Insert new actor
createActor -actorName "Salma Hayek" -showName "Sonia Kincaid" -movie "Hitmans Wifes Bodyguard" -location "Ottawa"

# Read specific actor
Write-Host "`n--- Read Kate Beckinsale ---" -ForegroundColor Black -BackgroundColor Cyan
readOneActor -actorName "Kate Beckinsale"

# Read all actors
Write-Host "`n--- Read All Actors ---" -ForegroundColor Black -BackgroundColor Cyan
readAllActors

# Update actor multiple fields
updateMultipleValues -actorName "Matt Leblanc" -heroName "Adam Burns" -movie "Man with a Plan" -location "Vancouver"

# Update single value
updateSingleValue -actorName "Matthew Perry" -newShowName "Ms. Chanandler Bong"

# Read Matt Leblanc after update
Write-Host "`n--- Read Matt Leblanc ---" -ForegroundColor Black -BackgroundColor Cyan
readOneActor -actorName "Matt Leblanc"

# Read Matthew Perry after update
Write-Host "`n--- Read Matthew Perry ---" -ForegroundColor Black -BackgroundColor Cyan
readOneActor -actorName "Matthew Perry"

# Delete a role by hero name
deleteActorByHero -heroName "August"

Write-Host "`nDONE!" -ForegroundColor White -BackgroundColor DarkGreen
