# mongo_crud_simple.ps1
# Simple CRUD using Mdbc (PowerShell module) - includes Chandler update
# Prereq: Install-Module Mdbc
Import-Module Mdbc -ErrorAction Stop

# Connect
Connect-Mdbc -Server "mongodb://localhost:27017" -Database "ActorsDB" -Collection "Actors"
$collection = Get-MdbcCollection

function createActor {
    param($actorName,$showName,$movie,$location)
    $doc = @{
        actorName = $actorName
        actorShowName = $showName
        roles = @(
            @{ heroName = $showName; seriesMovieTitle = $movie; location = $location }
        )
    }
    Add-MdbcData $doc
    Write-Host "Inserted $actorName"
}

function readOneActor { param($name) Find-MdbcData @{ actorName = $name } | Format-List }

function readAllActors { Get-MdbcData | Out-GridView -Title 'All Actors' }

function updateMultipleValues {
    param($actorName,$heroName,$movie,$location)
    $filter = @{ actorName = $actorName }
    $update = @{
        '$set' = @{ actorShowName = $heroName }
        '$push' = @{ roles = @{ heroName = $heroName; seriesMovieTitle = $movie; location = $location } }
    }
    Update-MdbcData $filter $update
    Write-Host "Updated $actorName"
}

function updateSingleValue {
    # Update the first role object to include actorShowName = Ms. Chanandler Bong
    $filter = @{ actorName = "Matthew Perry" }
    # Using a positional set for first role; if you want to change all roles use $[] array filters (requires driver support)
    $update = @{ '$set' = @{ 'roles.0.actorShowName' = 'Ms. Chanandler Bong' } }
    Update-MdbcData $filter $update
    Write-Host "Chandler updated to Ms. Chanandler Bong"
}

function deleteActor { param($hero) Remove-MdbcData @{ 'roles.heroName' = $hero }; Write-Host "Deleted role $hero" }

# Demo actions requested
# Insert actors
createActor -actorName "Salma Hayek" -showName "Sonia Kincaid" -movie "Hitmans Wifes Bodyguard" -location "Ottawa"

# Read specific actor
Write-Host "`n--- Read Kate Beckinsale ---" -ForegroundColor Black -BackgroundColor Cyan
readOneActor -actorName "Kate Beckinsale"

# Read all actors
Write-Host "`n--- Read All Actors ---" -ForegroundColor Black -BackgroundColor Cyan
readAllActors

# Update actor multiple fields
updateMultipleValues -actorName "Matt Leblanc" -heroName "Adam Burns" -movie "Man with a Plan" -location "Vancouver"

# Update Chandler's show name
updateSingleValue -actorName "Matthew Perry" -newShowName "Ms. Chanandler Bong"

# Read Matt Leblanc after update
Write-Host "`n--- Read Matt Leblanc ---" -ForegroundColor Black -BackgroundColor Cyan
readOneActor -actorName "Matt Leblanc"

# Read Matthew Perry after update
Write-Host "`n--- Read Matthew Perry ---" -ForegroundColor Black -BackgroundColor Cyan
readOneActor -actorName "Matthew Perry"

# Delete a role by hero name
deleteActor -heroName "August"

Write-Host "`nDONE!" -ForegroundColor White -BackgroundColor DarkGreen
