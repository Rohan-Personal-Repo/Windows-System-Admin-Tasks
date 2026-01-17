# mongo_normalize_and_crud_v2.ps1
# PowerShell 7 + Mdbc 7
# Full: Normalize existing actor documents (semi-normalized "shows" array) + CRUD
# - Normalizer is idempotent and verified 3x
# - All reads output to Out-GridView
# - Defensive, validated functions
# Usage: pwsh -File .\mongo_normalize_and_crud_v2.ps1

# ---------- CONFIG ----------
$Server      = "mongodb://localhost:27017"
$Database    = "ActorsDB"
$ActorsColl  = "Actors"
$ShowsColl   = "Shows"

# ---------- PREP ----------
Import-Module Mdbc -ErrorAction Stop

function Set-Collection {
    param(
        [string]$db,
        [string]$coll
    )
    Set-MdbcCollection -Database $db -Collection $coll
}

# Connect (set default to Actors)
Connect-Mdbc -Server $Server -Database $Database -Collection $ActorsColl

# ---------- HELPERS ----------
function Safe-GetProperty {
    param($obj, [string]$propName)
    if ($null -eq $obj) { return $null }
    if ($obj.PSObject.Properties.Name -contains $propName) { return $obj.$propName }
    return $null
}

# Ensure a Shows document exists; return its _id (created or existing)
function Get-OrCreateShow {
    param([string]$title)

    if (-not $title) { $title = "" }

    # switch to Shows collection
    Set-Collection -db $Database -coll $ShowsColl

    # exact match on seriesMovieTitle
    $found = Get-MdbcData -Filter @{ seriesMovieTitle = $title }
    if ($found) {
        return $found._id
    }

    # create
    $doc = @{
        seriesMovieTitle = $title
        createdAt = (Get-Date)
    }
    try {
        Add-MdbcData -InputObject $doc | Out-Null
        # read back inserted doc
        $added = Get-MdbcData -Filter @{ seriesMovieTitle = $title }
        return $added._id
    }
    catch {
        Write-Host "ERROR creating show: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
    finally {
        # switch back
        Set-Collection -db $Database -coll $ActorsColl
    }
}

# ---------- NORMALIZER ----------
# Convert existing actor documents to semi-normalized form:
# - roles (object or array) -> shows (array of { showId, heroName, location })
function Normalize-AllActors {
    Write-Host "`nStarting normalization pass..." -ForegroundColor Cyan

    Set-Collection -db $Database -coll $ActorsColl
    $all = Get-MdbcData

    foreach ($doc in $all) {
        try {
            # read roles property safely
            $rolesVal = Safe-GetProperty -obj $doc -propName 'roles'

            if ($null -eq $rolesVal) {
                # nothing to normalize for this doc
                continue
            }

            # Normalize roles into an array (if it's a single object)
            if ($rolesVal -isnot [System.Collections.IEnumerable] -or $rolesVal -is [string]) {
                $rolesArray = @($rolesVal)
            }
            else {
                $rolesArray = $rolesVal
            }

            # If rolesArray is empty or contains only $null, skip
            if (-not $rolesArray -or $rolesArray.Count -eq 0) { continue }

            # Build shows array
            $showsArray = @()
            foreach ($r in $rolesArray) {
                # Safe property extraction
                $hero    = Safe-GetProperty -obj $r -propName 'heroName'
                $title   = Safe-GetProperty -obj $r -propName 'seriesMovieTitle'
                $loc     = Safe-GetProperty -obj $r -propName 'location'

                if (-not $hero)  { $hero = "" }
                if (-not $title) { $title = "" }
                if (-not $loc)   { $loc = "" }

                # ensure Show doc exists and get its id
                $showId = Get-OrCreateShow -title $title

                $entry = @{
                    showId   = $showId
                    heroName = $hero
                    location = $loc
                }
                $showsArray += $entry
            }

            # Update actor document: set shows (array) and remove roles
            $filter = @{ _id = $doc._id }
            $update = @{
                '$set' = @{ shows = $showsArray }
                '$unset' = @{ roles = "" }
            }

            Update-MdbcData -Filter $filter -Update $update

            Write-Host "Normalized actor: $($doc.actorName)" -ForegroundColor Green
        }
        catch {
            Write-Host "Normalization error for actor $($doc.actorName): $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host "Normalization pass complete." -ForegroundColor Cyan
}

# ---------- VERIFIER ----------
# Verify that all actor documents now have 'shows' as an array and no 'roles' field.
function Verify-Normalization {
    Set-Collection -db $Database -coll $ActorsColl

    $all = Get-MdbcData
    $badCount = 0
    foreach ($d in $all) {
        $hasRoles = $false
        if ($d.PSObject.Properties.Name -contains 'roles') { $hasRoles = $true }

        # check shows is array
        $showsVal = Safe-GetProperty -obj $d -propName 'shows'
        $showsIsArray = ($showsVal -is [System.Collections.IEnumerable] -and -not ($showsVal -is [string]))

        if ($hasRoles -or -not $showsIsArray) {
            $badCount++
            Write-Host "Bad doc: $($d.actorName) - roles present: $hasRoles - showsIsArray: $showsIsArray" -ForegroundColor Yellow
        }
    }

    if ($badCount -eq 0) {
        Write-Host "Verification passed: All actor documents normalized (no 'roles' field; 'shows' is array)." -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "Verification FAILED: $badCount document(s) require normalization." -ForegroundColor Red
        return $false
    }
}

# ---------- CRUD FUNCTIONS (Actors + Shows) ----------
# Create Actor (with initial show)
function Create-Actor {
    param(
        [string]$actorName,
        [string]$heroName,
        [string]$seriesMovieTitle,
        [string]$location
    )
    if (-not $actorName) { throw "actorName is required" }

    $showId = Get-OrCreateShow -title $seriesMovieTitle

    $showsArr = @(
        @{
            showId = $showId
            heroName = ($heroName ?? "")
            location = ($location ?? "")
        }
    )

    Set-Collection -db $Database -coll $ActorsColl
    $doc = @{
        actorName = $actorName
        shows = $showsArr
        createdAt = (Get-Date)
    }

    Add-MdbcData -InputObject $doc
    Write-Host "Inserted actor: $actorName" -ForegroundColor Green
}

# Read all actors -> Out-GridView (flattened JSON to PS objects)
function Read-AllActors {
    Set-Collection -db $Database -coll $ActorsColl
    $all = Get-MdbcData
    if (-not $all) { Write-Host "No actor documents found." -ForegroundColor Yellow; return }
    $all | ConvertTo-Json -Depth 6 | ConvertFrom-Json | Out-GridView -Title "All Actors"
}

# Read single actor -> Out-GridView
function Read-Actor {
    param([string]$actorName)
    if (-not $actorName) { throw "actorName required" }
    Set-Collection -db $Database -coll $ActorsColl
    $found = Get-MdbcData -Filter @{ actorName = $actorName }
    if (-not $found) { Write-Host "Actor '$actorName' not found." -ForegroundColor Yellow; return }
    $found | ConvertTo-Json -Depth 6 | ConvertFrom-Json | Out-GridView -Title "Actor: $actorName"
}

# Add a role to an actor (adds show if missing)
function Add-RoleToActor {
    param(
        [string]$actorName,
        [string]$heroName,
        [string]$seriesMovieTitle,
        [string]$location
    )
    if (-not $actorName) { throw "actorName is required" }

    $showId = Get-OrCreateShow -title $seriesMovieTitle
    $newEntry = @{
        showId = $showId
        heroName = ($heroName ?? "")
        location = ($location ?? "")
    }

    Set-Collection -db $Database -coll $ActorsColl
    Update-MdbcData -Filter @{ actorName = $actorName } -Update @{ '$push' = @{ shows = $newEntry } }
    Write-Host "Added role '$($newEntry.heroName)' to $actorName" -ForegroundColor Yellow
}

# Update FIRST role's heroName (Chandler example)
function Update-FirstRoleHeroName {
    param(
        [string]$actorName,
        [string]$newHeroName
    )
    if (-not $actorName) { throw "actorName is required" }

    Set-Collection -db $Database -coll $ActorsColl
    Update-MdbcData -Filter @{ actorName = $actorName } -Update @{ '$set' = @{ 'shows.0.heroName' = ($newHeroName ?? "") } }
    Write-Host "Updated first role heroName for $actorName -> $newHeroName" -ForegroundColor Cyan
}

# Delete role(s) by heroName (pull from all actor documents)
function Delete-RoleByHeroName {
    param([string]$heroName)
    if (-not $heroName) { throw "heroName required" }

    Set-Collection -db $Database -coll $ActorsColl
    Update-MdbcData -Filter @{ "shows.heroName" = $heroName } -Update @{ '$pull' = @{ shows = @{ heroName = $heroName } } }
    Write-Host "Removed role(s) with heroName = $heroName" -ForegroundColor Red
}

# Delete entire actor document
function Delete-Actor {
    param([string]$actorName)
    if (-not $actorName) { throw "actorName required" }

    Set-Collection -db $Database -coll $ActorsColl
    Remove-MdbcData -Filter @{ actorName = $actorName }
    Write-Host "Deleted actor: $actorName" -ForegroundColor Red
}

# Read Shows collection
function Read-AllShows {
    Set-Collection -db $Database -coll $ShowsColl
    $all = Get-MdbcData
    if (-not $all) { Write-Host "No shows found." -ForegroundColor Yellow; return }
    $all | ConvertTo-Json -Depth 4 | ConvertFrom-Json | Out-GridView -Title "All Shows"
}

# ---------- NORMALIZE + VERIFY (3x) ----------
Normalize-AllActors

# Verify 3 times to ensure idempotency
for ($i = 1; $i -le 3; $i++) {
    Write-Host "`nVerification pass #$i ..." -ForegroundColor Cyan
    $ok = Verify-Normalization
    if ($ok) {
        Write-Host "Pass #$i OK" -ForegroundColor Green
    } else {
        Write-Host "Pass #$i found issues — re-running normalization..." -ForegroundColor Yellow
        Normalize-AllActors
    }
}

Write-Host "`nNormalization & verification complete.`n" -ForegroundColor Green

# ---------- SAMPLE USAGE (uncomment to run) ----------

# Seed one actor (example)
Create-Actor -actorName "Salma Hayek" -heroName "Sonia Kincaid" -seriesMovieTitle "Hitman's Wife's Bodyguard" -location "Ottawa"

# Show all actors
Read-AllActors

# Read one actor
Read-Actor -actorName "Kate Beckinsale"

# Add role
Add-RoleToActor -actorName "Matt Leblanc" -heroName "Adam Burns" -seriesMovieTitle "Man with a Plan" -location "Vancouver"

# Update first role heroName (Chandler example)
Update-FirstRoleHeroName -actorName "Matthew Perry" -newHeroName "Ms. Chanandler Bong"

# Delete role by hero name
Delete-RoleByHeroName -heroName "August"

# Delete actor
Delete-Actor -actorName "Some Actor"


Write-Host "`nScript ready. Use functions like Create-Actor, Read-AllActors, Read-Actor, Add-RoleToActor, Update-FirstRoleHeroName, Delete-RoleByHeroName." -ForegroundColor White -BackgroundColor DarkGreen
