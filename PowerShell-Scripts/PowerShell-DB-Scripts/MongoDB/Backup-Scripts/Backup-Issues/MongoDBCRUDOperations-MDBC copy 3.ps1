# mongo_normalize_and_crud.ps1
# PowerShell 7 + Mdbc 7
# NORMALIZE existing embedded roles -> semi-normalized shows + CRUD
# Usage: pwsh -File .\mongo_normalize_and_crud.ps1

Import-Module Mdbc -ErrorAction Stop

# Config
$Server = "mongodb://localhost:27017"
$Database = "ActorsDB"
$ActorsColl = "Actors"
$ShowsColl = "Shows"

function Set-Collection {
    param($db, $coll)
    Set-MdbcCollection -Database $db -Collection $coll
}

# Connect (sets default collection)
Connect-Mdbc -Server $Server -Database $Database -Collection $ActorsColl

Write-Host "Connected to $Server / $Database" -ForegroundColor Cyan

# -----------------------------------------------------------
# Helper: ensure show exists in Shows collection; returns showId
# -----------------------------------------------------------
function Get-OrCreateShow {
    param([string]$title)

    # switch to Shows collection
    Set-Collection -db $Database -coll $ShowsColl

    $found = Get-MdbcData -Filter @{ seriesMovieTitle = $title }
    if ($found) {
        $id = $found._id
    }
    else {
        $doc = @{ seriesMovieTitle = $title; createdAt = (Get-Date) }
        $res = Add-MdbcData -InputObject $doc
        # Get inserted doc (query back)
        $added = Get-MdbcData -Filter @{ seriesMovieTitle = $title }
        $id = $added._id
    }

    # switch back to Actors
    Set-Collection -db $Database -coll $ActorsColl
    return $id
}

# -----------------------------------------------------------
# NORMALIZE: convert existing documents so each actor has "shows" array
# shows = [ { showId: ObjectId, heroName: string, location: string } ]
# This will:
#  - ensure roles field is an array
#  - for each role create/get a Shows doc and replace roles with shows ref array
# -----------------------------------------------------------
function Normalize-AllActors {

    Write-Host "`nNormalizing All Actors..." -ForegroundColor Cyan

    $all = Get-MdbcData

    $output = foreach ($a in $all) {

        # Extract actorName safely
        $actorName = $a.actorName
        if (-not $actorName) { $actorName = "" }

        # Normalize roles to array form
        $roles = $a.roles

        if ($roles -isnot [System.Collections.IEnumerable] -or
            $roles -is [string] -or
            $roles -is [int]) {

            # Convert single object → array of 1
            $roles = @($roles)
        }

        foreach ($r in $roles) {

            # Hero Name
            $hero = $null
            if ($r -and $r.PSObject.Properties.Name -contains "heroName") {
                $hero = $r.heroName
            }
            if (-not $hero) { $hero = "" }

            # Series/Movie Title (FIXED: safe property access)
            $title = $null
            if ($r -and $r.PSObject.Properties.Name -contains "seriesMovieTitle") {
                $title = $r.seriesMovieTitle
            }
            if (-not $title) { $title = "" }

            # Location
            $location = $null
            if ($r -and $r.PSObject.Properties.Name -contains "location") {
                $location = $r.location
            }
            if (-not $location) { $location = "" }

            # Emit flattened row
            [PSCustomObject]@{
                ActorName         = $actorName
                HeroName          = $hero
                SeriesMovieTitle  = $title
                Location          = $location
            }
        }
    }

    # Show result in Out-GridView
    $output | Out-GridView -Title "Normalized Output"

    return $output
}


# -----------------------------------------------------------
# CRUD Functions (Actors & Shows) - using semi-normalized structure
# -----------------------------------------------------------

# Create Actor (with initial show reference)
function Create-Actor {
    param(
        [string]$actorName,
        [string]$heroName,
        [string]$seriesMovieTitle,
        [string]$location
    )

    # ensure show exists
    $showId = Get-OrCreateShow -title $seriesMovieTitle

    $showsArr = @(
        @{
            showId = $showId
            heroName = $heroName
            location = $location
        }
    )

    Set-Collection -db $Database -coll $ActorsColl
    $doc = @{ actorName = $actorName; shows = $showsArr; createdAt = (Get-Date) }
    Add-MdbcData -InputObject $doc
    Write-Host "Inserted actor: $actorName" -ForegroundColor Green
}

# Read actor(s) -> Out-GridView
function Read-AllActors {
    Set-Collection -db $Database -coll $ActorsColl
    Get-MdbcData | ConvertTo-Json -Depth 5 | ConvertFrom-Json | Out-GridView -Title "All Actors"
}

function Read-Actor {
    param([string]$actorName)
    Set-Collection -db $Database -coll $ActorsColl
    Get-MdbcData -Filter @{ actorName = $actorName } | ConvertTo-Json -Depth 5 | ConvertFrom-Json | Out-GridView -Title "Actor: $actorName"
}

# Update: add a new role (adds show if missing, pushes into actor.shows)
function Add-RoleToActor {
    param(
        [string]$actorName,
        [string]$heroName,
        [string]$seriesMovieTitle,
        [string]$location
    )

    $showId = Get-OrCreateShow -title $seriesMovieTitle

    $newEntry = @{
        showId = $showId
        heroName = $heroName
        location = $location
    }

    Set-Collection -db $Database -coll $ActorsColl
    $filter = @{ actorName = $actorName }
    $update = @{ '$push' = @{ shows = $newEntry } }

    Update-MdbcData -Filter $filter -Update $update
    Write-Host "Added role '$heroName' to $actorName" -ForegroundColor Yellow
}

# Update single: change first show's heroName (Chandler example)
function Update-FirstRoleHeroName {
    param(
        [string]$actorName,
        [string]$newHeroName
    )

    Set-Collection -db $Database -coll $ActorsColl
    $filter = @{ actorName = $actorName }
    $update = @{ '$set' = @{ 'shows.0.heroName' = $newHeroName } }

    Update-MdbcData -Filter $filter -Update $update
    Write-Host "Updated first role heroName for $actorName -> $newHeroName" -ForegroundColor Cyan
}

# Delete role by hero name (removes entries from actor.shows)
function Delete-RoleByHeroName {
    param([string]$heroName)

    Set-Collection -db $Database -coll $ActorsColl
    $filter = @{ "shows.heroName" = $heroName }
    $update = @{ '$pull' = @{ shows = @{ heroName = $heroName } } }

    Update-MdbcData -Filter $filter -Update $update
    Write-Host "Removed role(s) with heroName = $heroName" -ForegroundColor Red
}

# Remove actor completely
function Delete-Actor {
    param([string]$actorName)
    Set-Collection -db $Database -coll $ActorsColl
    Remove-MdbcData -Filter @{ actorName = $actorName }
    Write-Host "Deleted actor: $actorName" -ForegroundColor Red
}

# Show helper: Read all shows
function Read-AllShows {
    Set-Collection -db $Database -coll $ShowsColl
    Get-MdbcData | ConvertTo-Json -Depth 5 | ConvertFrom-Json | Out-GridView -Title "All Shows"
}

# -----------------------------------------------------------
# Run Normalizer once (safe: idempotent)
# -----------------------------------------------------------
Normalize-AllActors

# -----------------------------------------------------------
# Demo actions (comment/uncomment as needed)
# -----------------------------------------------------------
Create-Actor -actorName "Salma Hayek" -heroName "Sonia Kincaid" -seriesMovieTitle "Hitman's Wife's Bodyguard" -location "Ottawa"
Read-Actor -actorName "Kate Beckinsale"
Read-AllActors
Add-RoleToActor -actorName "Matt Leblanc" -heroName "Adam Burns" -seriesMovieTitle "Man with a Plan" -location "Vancouver"
Update-FirstRoleHeroName -actorName "Matthew Perry" -newHeroName "Ms. Chanandler Bong"
Delete-RoleByHeroName -heroName "August"

Write-Host "`nScript ready. Use functions like Create-Actor, Read-AllActors, Add-RoleToActor, Update-FirstRoleHeroName." -ForegroundColor Green
