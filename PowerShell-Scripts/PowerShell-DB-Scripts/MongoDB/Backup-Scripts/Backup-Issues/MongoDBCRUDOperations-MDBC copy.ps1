# mongo_crud.ps1
# Clean CRUD for Actors + Roles using Mdbc (PowerShell)

Import-Module Mdbc -ErrorAction Stop

# ------------------------------------------------------------
# 1. CONNECT TO MONGO
# ------------------------------------------------------------
Connect-Mdbc -Server "mongodb://localhost:27017" `
             -Database "ActorsDB" `
             -Collection "Actors"

$collection = Get-MdbcCollection


# ------------------------------------------------------------
# 2. CREATE
# ------------------------------------------------------------
function createActor {
    param(
        [string]$actorName,
        [string]$heroName,
        [string]$seriesMovieTitle,
        [string]$location
    )

    $doc = @{
        actorName = $actorName
        roles = @(
            @{
                heroName = $heroName
                seriesMovieTitle = $seriesMovieTitle
                location = $location
            }
        )
    }

    Add-MdbcData $doc
    Write-Host "Inserted actor: $actorName" -ForegroundColor Green
}


# ------------------------------------------------------------
# 3. READ ONE (LIST FORMAT)
# ------------------------------------------------------------
function readOneActor {
    param([string]$actorName)

    Find-MdbcData @{ actorName = $actorName } |
        Format-List
}


# ------------------------------------------------------------
# 4. READ ALL (OUT-GRIDVIEW)
# ------------------------------------------------------------
function readAllActors {
    Get-MdbcData | Out-GridView -Title "All Actors"
}


# ------------------------------------------------------------
# 5. UPDATE MULTIPLE - ADD NEW ROLE + UPDATE actorShowName
# ------------------------------------------------------------
function updateMultipleValues {
    param(
        [string]$actorName,
        [string]$heroName,
        [string]$seriesMovieTitle,
        [string]$location
    )

    $filter = @{ actorName = $actorName }

    $update = @{
        '$push' = @{
            roles = @{
                heroName = $heroName
                seriesMovieTitle = $seriesMovieTitle
                location = $location
            }
        }
    }

    Update-MdbcData $filter $update
    Write-Host "Updated $actorName (added new role)" -ForegroundColor Yellow
}


# ------------------------------------------------------------
# 6. UPDATE SINGLE VALUE (E.G. CHANDLER BING -> MS. CHANANDLER BONG)
# ------------------------------------------------------------
function updateSingleValue {
    param(
        [string]$actorName,
        [string]$newShowName
    )

    # updates ONLY the first role heroName
    $filter = @{ actorName = $actorName }

    $update = @{
        '$set' = @{
            "roles.0.heroName" = $newShowName
        }
    }

    Update-MdbcData $filter $update

    Write-Host "Updated first role of $actorName → $newShowName" -ForegroundColor Yellow
}


# ------------------------------------------------------------
# 7. DELETE ROLE BY heroName
# ------------------------------------------------------------
function deleteActor {
    param([string]$heroName)

    $filter = @{ "roles.heroName" = $heroName }
    $update = @{
        '$pull' = @{
            roles = @{ heroName = $heroName }
        }
    }

    Update-MdbcData $filter $update

    Write-Host "Deleted all roles with heroName = $heroName" -ForegroundColor Red
}


# ------------------------------------------------------------
# 8. OPTIONAL: SEEDING DATA (comment out when not needed)
# ------------------------------------------------------------

# Example Insert
createActor -actorName "Salma Hayek" `
           -heroName "Sonia Kincaid" `
           -seriesMovieTitle "Hitmans Wifes Bodyguard" `
           -location "Ottawa"

# Example Read
readOneActor -actorName "Kate Beckinsale"

readAllActors

# Example Add/update
updateMultipleValues -actorName "Matt Leblanc" -heroName "Adam Burns" `
                    -seriesMovieTitle "Man with a Plan" -location "Vancouver"

# Example Chandler Update
updateSingleValue -actorName "Matthew Perry" -newShowName "Ms. Chanandler Bong"

# Example Delete
deleteActor -heroName "August"

Write-Host "`nDONE! Mongo CRUD ready." -ForegroundColor White -BackgroundColor DarkGreen
