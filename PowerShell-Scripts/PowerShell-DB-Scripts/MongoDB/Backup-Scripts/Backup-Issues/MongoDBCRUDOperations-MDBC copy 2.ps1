# ---------------------------------------------------------------
# mongo_crud_v7.ps1
# Compatible with PowerShell 7 + Mdbc 7
# Full CRUD for Actors + Roles collection
# ---------------------------------------------------------------

Import-Module Mdbc -ErrorAction Stop

# -------------------- CONNECTION ------------------------------
Connect-Mdbc -ConnectionString "mongodb+srv://mongoDBUserName:mongoDBPassword@mongocluster.dev.mongodb.net/" `
             -DatabaseName "ActorsDatabase" `
             -CollectionName "ActorsData"

$collection = Get-MdbcCollection


# ---------------------- CREATE -------------------------------
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

    Add-MdbcData -InputObject $doc
    Write-Host "Inserted actor: $actorName" -ForegroundColor Green
}


# ---------------------- READ ONE -----------------------------
function readOneActor {
    param([string]$actorName)

    Find-MdbcData @{ actorName = $actorName } |
        Out-GridView -Title "Actor: $actorName"
}


# ---------------------- READ ALL -----------------------------
function readAllActors {
    Get-MdbcData | Out-GridView -Title "All Actors"
}


# ---------------------- UPDATE MULTIPLE ----------------------
function updateMultipleValues {
    param(
        [string]$actorName,
        [string]$heroName,
        [string]$seriesMovieTitle,
        [string]$location
    )

    $filter = @{ actorName = $actorName }

    $newRole = @{
        heroName = $heroName
        seriesMovieTitle = $seriesMovieTitle
        location = $location
    }

    $update = @{
        '$push' = @{ roles = $newRole }
    }

    Update-MdbcData -Filter $filter -Update $update

    Write-Host "Updated $actorName (added role: $heroName)" -ForegroundColor Yellow
}


# ---------------------- UPDATE SINGLE VALUE ------------------
function updateSingleValue {
    param(
        [string]$actorName,
        [string]$newShowName
    )

    # Ensure roles is always treated as an array for Mdbc 7
    $filter = @{ actorName = $actorName }

    # Only updates the FIRST role
    $update = @{
        '$set' = @{
            "roles.0.heroName" = $newShowName
        }
    }

    Update-MdbcData -Filter $filter -Update $update

    Write-Host "Updated $actorName → first heroName set to $newShowName" -ForegroundColor Cyan
}


# ---------------------- DELETE ROLE --------------------------
function deleteActor {
    param([string]$heroName)

    $filter = @{ "roles.heroName" = $heroName }

    $update = @{
        '$pull' = @{
            roles = @{ heroName = $heroName }
        }
    }

    Update-MdbcData -Filter $filter -Update $update

    Write-Host "Deleted all roles where heroName = $heroName" -ForegroundColor Red
}


# ---------------------- SCRIPT READY -------------------------
Write-Host "`nMongo CRUD ready for PowerShell 7 + Mdbc 7" `
           -ForegroundColor White -BackgroundColor DarkGreen

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
