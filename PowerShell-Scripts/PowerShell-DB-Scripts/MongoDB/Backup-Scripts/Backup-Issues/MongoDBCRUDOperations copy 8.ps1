# MongoDB connection string
$connectionString = "mongodb+srv://mongoDBUserName:mongoDBPassword@mongocluster.dev.mongodb.net/"

# Escape quotes safely
function Escape-Quotes($str) {
    return $str.Replace('"','\"')
}

# --------------------------
# Normalize roles to arrays (run once before push/pull)
# --------------------------
function Normalize-Roles {
    $cmd = @'
db.ActorsData.find({}).forEach(doc => {
    if (!Array.isArray(doc.roles)) {
        db.ActorsData.updateOne(
            { _id: doc._id },
            { $set: { roles: [ doc.roles ] } }
        )
    }
})
'@
    mongosh $connectionString --quiet --eval $cmd
    Write-Host "Normalized all roles to arrays" -ForegroundColor Green
}

# --------------------------
# CRUD Functions
# --------------------------
function Create-Actor {
    param($actorName, $showName, $movie, $location)

    $actorNameSafe = Escape-Quotes $actorName
    $showNameSafe  = Escape-Quotes $showName
    $movieSafe     = Escape-Quotes $movie
    $locationSafe  = Escape-Quotes $location

    $cmd = @'
db.ActorsData.insertOne({
    actorName: "' + $actorNameSafe + '",
    actorShowName: "' + $showNameSafe + '",
    roles: [ { heroName: "' + $showNameSafe + '", seriesMovieTitle: "' + $movieSafe + '", location: "' + $locationSafe + '" } ]
})
'@
    mongosh $connectionString --quiet --eval $cmd
    Write-Host "Inserted $actorName" -ForegroundColor White -BackgroundColor DarkGreen
}

function Read-OneActor {
    param($actorName)
    $actorNameSafe = Escape-Quotes $actorName

    $cmd = @'
JSON.stringify(
    db.ActorsData.find({ actorName: "' + $actorNameSafe + '" }).toArray()
    .map(doc => ({ ...doc, _id: doc._id.toString() }))
)
'@
    $jsonOutput = mongosh $connectionString --quiet --eval $cmd
    $psObjects = $jsonOutput | ConvertFrom-Json
    $psObjects | Out-GridView -Title "Actor: $actorName"
}

function Read-AllActors {
    $cmd = @'
JSON.stringify(
    db.ActorsData.find({}).toArray()
    .map(doc => ({ ...doc, _id: doc._id.toString() }))
)
'@
    $jsonOutput = mongosh $connectionString --quiet --eval $cmd
    $psObjects = $jsonOutput | ConvertFrom-Json
    $psObjects | Out-GridView -Title "All Actors"
}

function Update-SingleValue {
    param($actorName, $newShowName)
    $actorNameSafe   = Escape-Quotes $actorName
    $newShowNameSafe = Escape-Quotes $newShowName

    $cmd = @'
db.ActorsData.updateOne(
    { actorName: "' + $actorNameSafe + '" },
    { $set: { actorShowName: "' + $newShowNameSafe + '" } }
)
'@
    mongosh $connectionString --quiet --eval $cmd
    Write-Host "$actorName updated to $newShowName" -ForegroundColor White -BackgroundColor DarkMagenta
}

function Update-MultipleValues {
    param($actorName, $heroName, $movie, $location)
    $actorNameSafe = Escape-Quotes $actorName
    $heroNameSafe  = Escape-Quotes $heroName
    $movieSafe     = Escape-Quotes $movie
    $locationSafe  = Escape-Quotes $location

    $cmd = @'
db.ActorsData.updateOne(
    { actorName: "' + $actorNameSafe + '" },
    {
        $set: { actorShowName: "' + $heroNameSafe + '" },
        $push: { roles: { heroName: "' + $heroNameSafe + '", seriesMovieTitle: "' + $movieSafe + '", location: "' + $locationSafe + '" } }
    }
)
'@
    mongosh $connectionString --quiet --eval $cmd
    Write-Host "Updated $actorName with new role $heroName" -ForegroundColor Black -BackgroundColor Yellow
}

function Remove-Role {
    param($heroName)
    $heroNameSafe = Escape-Quotes $heroName
    $cmd = @'
db.ActorsData.updateMany(
    {},
    { $pull: { roles: { heroName: "' + $heroNameSafe + '" } } }
)
'@
    mongosh $connectionString --quiet --eval $cmd
    Write-Host "Deleted role $heroName from all actors" -ForegroundColor White -BackgroundColor DarkRed
}

# --------------------------
# DEMO
# --------------------------

Normalize-Roles

Create-Actor -actorName "Salma Hayek" -showName "Sonia Kincaid" -movie "Hitmans Wifes Bodyguard" -location "Ottawa"

Write-Host "`n--- Read Kate Beckinsale ---" -ForegroundColor Black -BackgroundColor Cyan
Read-OneActor -actorName "Kate Beckinsale"

Write-Host "`n--- Read All Actors ---" -ForegroundColor Black -BackgroundColor Cyan
Read-AllActors

Update-MultipleValues -actorName "Matt Leblanc" -heroName "Adam Burns" -movie "Man with a Plan" -location "Vancouver"

Update-SingleValue -actorName "Matthew Perry" -newShowName "Ms. Chanandler Bong"

Write-Host "`n--- Read Matt Leblanc ---" -ForegroundColor Black -BackgroundColor Cyan
Read-OneActor -actorName "Matt Leblanc"

Write-Host "`n--- Read Matthew Perry ---" -ForegroundColor Black -BackgroundColor Cyan
Read-OneActor -actorName "Matthew Perry"

Remove-Role -heroName "August"

Write-Host "`nDONE!" -ForegroundColor White -BackgroundColor DarkGreen
