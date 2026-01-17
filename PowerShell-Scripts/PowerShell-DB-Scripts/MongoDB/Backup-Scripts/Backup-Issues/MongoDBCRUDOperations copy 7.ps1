# --------------------------
# MongoDB Connection String
# --------------------------
$connectionString = "mongodb+srv://mongoDBUserName:mongoDBPassword@mongocluster.dev.mongodb.net/"

# --------------------------
# Helper: Escape quotes for JS
# --------------------------
function Escape-Quotes {
    param($str)
    return $str.Replace("'", "\'")
}

# --------------------------
# Normalize roles: convert object to array if needed
# --------------------------
function Normalize-Roles {
    $cmd = "db.ActorsData.updateMany({ roles: { `$type: 'object' } }, [ { `$set: { roles: [`$roles`] } } ])"
    mongosh $connectionString --quiet --eval $cmd
    Write-Host "Normalized all roles to arrays" -ForegroundColor Green
}

# --------------------------
# CRUD Functions
# --------------------------

# Create actor
function Create-Actor {
    param($actorName,$showName,$movie,$location)
    $actorNameSafe = Escape-Quotes $actorName
    $showNameSafe  = Escape-Quotes $showName
    $movieSafe     = Escape-Quotes $movie
    $locationSafe  = Escape-Quotes $location

    $cmd = "db.ActorsData.insertOne({ actorName: '$actorNameSafe', actorShowName: '$showNameSafe', roles: [{ heroName: '$showNameSafe', seriesMovieTitle: '$movieSafe', location: '$locationSafe' }] })"
    mongosh $connectionString --quiet --eval $cmd
    Write-Host "Inserted $actorName" -ForegroundColor White -BackgroundColor DarkGreen
}

# Read one actor
function Read-OneActor {
    param($actorName)
    $actorNameSafe = Escape-Quotes $actorName
    $cmd = "JSON.stringify(db.ActorsData.find({ actorName: '$actorNameSafe' }).toArray().map(doc => ({ ...doc, _id: doc._id.toString() })))"

    $jsonOutput = mongosh $connectionString --quiet --eval $cmd
    $psObjects = $jsonOutput | ConvertFrom-Json
    $psObjects | Out-GridView -Title "Actor: $actorName"
}

# Read all actors
function Read-AllActors {
    $cmd = "JSON.stringify(db.ActorsData.find({}).toArray().map(doc => ({ ...doc, _id: doc._id.toString() })))"

    $jsonOutput = mongosh $connectionString --quiet --eval $cmd
    $psObjects = $jsonOutput | ConvertFrom-Json
    $psObjects | Out-GridView -Title "All Actors"
}

# Update single value ($set)
function Update-ActorShowName {
    param($actorName, $newShowName)
    $actorNameSafe   = Escape-Quotes $actorName
    $newShowNameSafe = Escape-Quotes $newShowName

    $cmd = "db.ActorsData.updateOne({ actorName: '$actorNameSafe' }, { `$set: { actorShowName: '$newShowNameSafe' } })"
    mongosh $connectionString --quiet --eval $cmd
    Write-Host "$actorName updated to $newShowName" -ForegroundColor White -BackgroundColor DarkMagenta
}

# Update multiple values ($set + $push)
function Add-RoleToActor {
    param($actorName,$heroName,$movie,$location)
    $actorNameSafe = Escape-Quotes $actorName
    $heroNameSafe  = Escape-Quotes $heroName
    $movieSafe     = Escape-Quotes $movie
    $locationSafe  = Escape-Quotes $location

    $cmd = "db.ActorsData.updateOne({ actorName: '$actorNameSafe' }, { `$set: { actorShowName: '$heroNameSafe' }, `$push: { roles: { heroName: '$heroNameSafe', seriesMovieTitle: '$movieSafe', location: '$locationSafe' } } })"
    mongosh $connectionString --quiet --eval $cmd
    Write-Host "Updated $actorName with new role $heroName" -ForegroundColor Black -BackgroundColor Yellow
}

# Remove role ($pull)
function Remove-RoleFromActor {
    param($heroName)
    $heroNameSafe = Escape-Quotes $heroName
    $cmd = "db.ActorsData.updateMany({}, { `$pull: { roles: { heroName: '$heroNameSafe' } } })"
    mongosh $connectionString --quiet --eval $cmd
    Write-Host "Deleted role $heroName from all actors" -ForegroundColor White -BackgroundColor DarkRed
}

# --------------------------
# DEMO
# --------------------------

# Normalize roles first
Normalize-Roles

# Insert actors
Create-Actor -actorName "Salma Hayek" -showName "Sonia Kincaid" -movie "Hitman's Wife Bodyguard" -location "Ottawa"

# Read specific actor
Write-Host "`n--- Read Kate Beckinsale ---" -ForegroundColor Black -BackgroundColor Cyan
Read-OneActor -actorName "Kate Beckinsale"

# Read all actors
Write-Host "`n--- Read All Actors ---" -ForegroundColor Black -BackgroundColor Cyan
Read-AllActors

# Update actor multiple fields
Add-RoleToActor -actorName "Matt Leblanc" -heroName "Adam Burns" -movie "Man with a Plan" -location "Vancouver"

# Update show name only
Update-ActorShowName -actorName "Matthew Perry" -newShowName "Ms. Chanandler Bong"

# Read after updates
Write-Host "`n--- Read Matt Leblanc ---" -ForegroundColor Black -BackgroundColor Cyan
Read-OneActor -actorName "Matt Leblanc"

Write-Host "`n--- Read Matthew Perry ---" -ForegroundColor Black -BackgroundColor Cyan
Read-OneActor -actorName "Matthew Perry"

# Remove a role by hero name
Remove-RoleFromActor -heroName "August"

Write-Host "`nDONE!" -ForegroundColor White -BackgroundColor DarkGreen
