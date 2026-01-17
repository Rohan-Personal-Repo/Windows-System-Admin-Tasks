# Import the Module and Stop if any Error Occurs
Import-Module Mdbc -ErrorAction Stop

# Adjust server/db/collection as needed
Connect-Mdbc -ConnectionString "mongodb+srv://mongoDBUserName:mongoDBPassword@mongocluster.dev.mongodb.net/" `
             -DatabaseName "ActorsDatabase" `
             -CollectionName "ActorsData"

# Helper: build/merge role object
function New-Role {
    param(
        [string]$heroName,
        [string]$seriesMovieTitle,
        [string]$location
    )
    [PSCustomObject]@{
        roleName         = $heroName
        seriesMovieTitle = $seriesMovieTitle
        Address          = $location
    }
}

# Create: insert actor (append roles if actor exists)
function createActor {
    param(
        [Parameter(Mandatory)][string]$actorName,
        [Parameter(Mandatory)][string]$heroName,
        [Parameter(Mandatory)][string]$seriesMovieTitle,
        [Parameter(Mandatory)][string]$location
    )

    $role = New-Role -heroName $heroName `
                     -seriesMovieTitle $seriesMovieTitle `
                     -location $location

    # Use -Filter and -First 1
    $existing = Get-MdbcData -Filter @{ heroName = $actorName } -First 1 -As PS

    if ($existing) {
        Update-MdbcData `
            -Filter @{ heroName = $actorName } `
            -Update @{ '$push' = @{ roles = $role } }
    }
    else {
        $doc = [PSCustomObject]@{
            heroName = $actorName
            roles    = @($role)
        }
        Add-MdbcData -InputObject $doc
    }
}

# Read: one actor
function readOneActor {
    param(
        [Parameter(Mandatory)] [string] $actorName,
        [Parameter(Mandatory)] [string] $gridTitle
    )

    $actor = Get-MdbcData -Filter @{ heroName = $actorName } -As PS

    if (-not $actor) {
        Write-Host "Actor '$actorName' not found."
        return
    }

    # Flatten roles: one row per role
    $rows = foreach ($a in $actor) {
        foreach ($r in $a.roles) {
            [PSCustomObject]@{
                ActorName        = $a.heroName
                RoleName         = $r.roleName
                SeriesMovieTitle = $r.seriesMovieTitle
                Location         = $r.Address
            }
        }
    }

    $rows | Out-GridView -Title $gridTitle
}


# Read: all actors
function readAllActors {

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
}

# Update: multiple fields in a single role
# Here, update is done by matching the existing roleName and then using the positional operator on that element in roles
function updateMultipleValues {
    param(
        [Parameter(Mandatory)][string]$actorName,
        [Parameter(Mandatory)][string]$heroName,
        [Parameter(Mandatory)][string]$seriesMovieTitle,
        [Parameter(Mandatory)][string]$location,
        [string]$matchHeroName = $null
    )

    if (-not $matchHeroName) { $matchHeroName = $heroName }

    $filter = @{
        heroName         = $actorName
        "roles.roleName" = $matchHeroName
    }

    $update = @{
        '$set' = @{
            "roles.$.roleName"         = $heroName
            "roles.$.seriesMovieTitle" = $seriesMovieTitle
            "roles.$.Address"          = $location
        }
    }

    Update-MdbcData -Filter $filter -Update $update
}


# Update: single value (change role name only)
function updateSingleValue {
    param(
        [Parameter(Mandatory)][string]$actorName,
        [Parameter(Mandatory)][string]$newShowName,
        [string]$matchHeroName = $null
    )

    if (-not $matchHeroName) { $matchHeroName = $newShowName }

    $filter = @{
        heroName         = $actorName
        "roles.roleName" = $matchHeroName
    }

    $update = @{
        '$set' = @{
            "roles.$.roleName" = $newShowName
        }
    }

    Update-MdbcData -Filter $filter -Update $update
}


# Delete: delete a role by hero name (keep actor document)
function deleteActorByHero {
    param(
        [Parameter(Mandatory)][string]$heroName
    )

    $filter = @{ "roles.roleName" = $heroName }

    $update = @{
        '$pull' = @{ roles = @{ roleName = $heroName } }
    }

    # Use -Filter and -Many
    Update-MdbcData -Filter $filter -Update $update -Many
}


# DEMO: CRUD Operations
# --------------------------

# Insert actor
createActor -actorName "Salma Hayek" `
            -heroName "Sonia Kincaid" `
            -seriesMovieTitle "Hitman's Wife's Bodyguard" `
            -location "Ottawa"

# Read specific actor
Write-Host "`n--- Read Kate Beckinsale ---" -ForegroundColor Cyan -BackgroundColor Black
readOneActor -actorName "Kate Beckinsale" -gridTitle "Read Single Actor"

# Read all actors
Write-Host "`n--- Read All Actors ---" -ForegroundColor Cyan -BackgroundColor Black
readAllActors

# Update actor multiple fields (update a specific role for Matt Leblanc)
Write-Host "`n--- Updating Multiple Values ---" -ForegroundColor Magenta -BackgroundColor White
updateMultipleValues -actorName "Matt Leblanc" `
                     -heroName "Adam Burns" `
                     -seriesMovieTitle "Man with a Plan" `
                     -location "Vancouver" `
                     -matchHeroName "Joey Tribbiani"

# Read after updates
Write-Host "`n--- Read Matt Leblanc after Update ---" -ForegroundColor Cyan -BackgroundColor Black
readOneActor -actorName "Matt Leblanc" -gridTitle "Added Role for Matt"

# Update single value (rename one of Matthew Perry's roles)
Write-Host "`n--- Updating Single Value ---" -ForegroundColor Magenta -BackgroundColor DarkRed
updateSingleValue -actorName "Matthew Perry" `
                  -newShowName "Ms. Chanandler Bong" `
                  -matchHeroName "Chandler Bing"

Write-Host "`n--- Read Matthew Perry after Update ---" -ForegroundColor Cyan -BackgroundColor Black
readOneActor -actorName "Matthew Perry" -gridTitle "Updated CharacterName for Chandler"

# Delete a role by hero name
Write-Host "`n--- Deleting August ---" -ForegroundColor DarkRed -BackgroundColor Yellow
deleteActorByHero -heroName "August"

Write-Host "`nDONE!" -ForegroundColor White -BackgroundColor DarkGreen
