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

    # If actor exists, push new role; else insert new document
    $existing = Get-MdbcData -Query @{ heroName = $actorName } -First

    if ($existing) {
        Update-MdbcData `
            -Query @{ heroName = $actorName } `
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
        [Parameter(Mandatory)][string]$actorName
    )

    $actor = Get-MdbcData -Filter @{ heroName = $actorName } -As PS

    if (-not $actor) {
        Write-Host "Actor '$actorName' not found."
    }
    else {
        $actor | Out-GridView -Title "Actor: $actorName"
    }
}

# Read: all actors
function readAllActors {

    # Flatten roles so each row in the grid is one role with the actor name
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
        [Parameter(Mandatory)][string]$heroName,          # new heroName
        [Parameter(Mandatory)][string]$seriesMovieTitle,  # new title
        [Parameter(Mandatory)][string]$location,          # new location
        [string]$matchHeroName = $null                    # optional: which role to update
    )

    # if not specified, assume we are updating the first matching role by actorName
    if (-not $matchHeroName) { $matchHeroName = $heroName }

    $query = @{
        heroName        = $actorName
        "roles.roleName" = $matchHeroName
    }

    $update = @{
        '$set' = @{
            "roles.$.roleName"         = $heroName
            "roles.$.seriesMovieTitle" = $seriesMovieTitle
            "roles.$.Address"          = $location
        }
    }

    Update-MdbcData -Query $query -Update $update
}

# Update: single value (change role name only)
function updateSingleValue {
    param(
        [Parameter(Mandatory)][string]$actorName,
        [Parameter(Mandatory)][string]$newShowName,  # new roleName
        [string]$matchHeroName = $null               # existing roleName to match
    )

    # If not specified, use the first matching role
    if (-not $matchHeroName) { $matchHeroName = $newShowName }

    $query = @{
        heroName        = $actorName
        "roles.roleName" = $matchHeroName
    }

    $update = @{
        '$set' = @{
            "roles.$.roleName" = $newShowName
        }
    }

    Update-MdbcData -Query $query -Update $update
}

# Delete: delete a role by hero name (keep actor document)
function deleteActorByHero {
    param(
        [Parameter(Mandatory)][string]$heroName
    )

    # Pull any roles with this heroName from all actors
    $query = @{ "roles.roleName" = $heroName }

    $update = @{
        '$pull' = @{ roles = @{ roleName = $heroName } }
    }

    Update-MdbcData -Query $query -Update $update -Many
}

# DEMO: CRUD Operations
# --------------------------

# Insert actor
createActor -actorName "Salma Hayek" `
            -heroName "Sonia Kincaid" `
            -seriesMovieTitle "Hitman's Wife's Bodyguard" `
            -location "Ottawa"

# Read specific actor
Write-Host "`n--- Read Kate Beckinsale ---" -ForegroundColor Black -BackgroundColor Cyan
readOneActor -actorName "Kate Beckinsale"

# Read all actors
Write-Host "`n--- Read All Actors ---" -ForegroundColor Black -BackgroundColor Cyan
readAllActors

# Update actor multiple fields (update a specific role for Matt Leblanc)
updateMultipleValues -actorName "Matt Leblanc" `
                     -heroName "Adam Burns" `
                     -seriesMovieTitle "Man with a Plan" `
                     -location "Vancouver" `
                     -matchHeroName "Joey Tribbiani"

# Update single value (rename one of Matthew Perry's roles)
updateSingleValue -actorName "Matthew Perry" `
                  -newShowName "Ms. Chanandler Bong" `
                  -matchHeroName "Chandler Bing"

# Read after updates
Write-Host "`n--- Read Matt Leblanc ---" -ForegroundColor Black -BackgroundColor Cyan
readOneActor -actorName "Matt Leblanc"

Write-Host "`n--- Read Matthew Perry ---" -ForegroundColor Black -BackgroundColor Cyan
readOneActor -actorName "Matthew Perry"

# Delete a role by hero name
deleteActorByHero -heroName "August"

Write-Host "`nDONE!" -ForegroundColor White -BackgroundColor DarkGreen
