# --------------------------
# MongoDB connection string
# --------------------------
$connectionString = "mongodb+srv://mongoDBUserName:mongoDBPassword@mongocluster.dev.mongodb.net/"

# --------------------------
# Helper: escape quotes
# --------------------------
function Escape-Quotes($str) {
    return $str.Replace('"','\"')
}

# --------------------------
# Normalize roles to arrays
# --------------------------
function Normalize-Roles {
    $cmd = @'
db.ActorsData.updateMany(
    { roles: { $type: "object" } },
    [ { $set: { roles: [ "$roles" ] } } ]
)
'@

    mongosh $connectionString --quiet --eval $cmd
    Write-Host "Normalized all roles to arrays" -ForegroundColor Green
}


# --------------------------
# CRUD Functions
# --------------------------

function createActor {
    param($actorName, $showName, $movie, $location)

    $actorNameSafe = Escape-Quotes $actorName
    $showNameSafe  = Escape-Quotes $showName
    $movieSafe     = Escape-Quotes $movie
    $locationSafe  = Escape-Quotes $location

    $cmd = @"
db.ActorsData.insertOne({
    actorName: '$actorNameSafe',
    actorShowName: '$showNameSafe',
    roles: [ { heroName: '$showNameSafe', seriesMovieTitle: '$movieSafe', location: '$locationSafe' } ]
})
"@

    mongosh $connectionString --quiet --eval $cmd
    Write-Host "Inserted $actorName" -ForegroundColor White -BackgroundColor DarkGreen
}

function readOneActor {
    param($actorName)
    $actorNameSafe = Escape-Quotes $actorName
    $cmd = @"
JSON.stringify(
    db.ActorsData.find({ actorName: '$actorNameSafe' }).toArray()
    .map(doc => ({ ...doc, _id: doc._id.toString() }))
)
"@
    $jsonOutput = mongosh $connectionString --quiet --eval $cmd
    if ($jsonOutput) {
        $psObjects = $jsonOutput | ConvertFrom-Json
        $psObjects | Out-GridView -Title "Actor: $actorName"
    } else {
        Write-Host "No actor found with name $actorName" -ForegroundColor Red
    }
}

function readAllActors {
    $cmd = @"
JSON.stringify(
    db.ActorsData.find({}).toArray()
    .map(doc => ({ ...doc, _id: doc._id.toString() }))
)
"@
    $jsonOutput = mongosh $connectionString --quiet --eval $cmd
    if ($jsonOutput) {
        $psObjects = $jsonOutput | ConvertFrom-Json
        $psObjects | Out-GridView -Title "All Actors"
    } else {
        Write-Host "No actors found" -ForegroundColor Red
    }
}

function updateMultipleValues {
    param($actorName, $heroName, $movie, $location)

    $actorNameSafe = Escape-Quotes $actorName
    $heroNameSafe  = Escape-Quotes $heroName
    $movieSafe     = Escape-Quotes $movie
    $locationSafe  = Escape-Quotes $location

    # Step 1: Convert roles object to array if needed
    $normalizeCmd = @"
db.ActorsData.find({ actorName: '$actorNameSafe' }).forEach(doc => {
    if (!Array.isArray(doc.roles)) {
        doc.roles = [doc.roles];
        db.ActorsData.save(doc);
    }
});
"@
    mongosh $connectionString --quiet --eval $normalizeCmd

    # Step 2: Push the new role and update actorShowName
    $cmd = @"
db.ActorsData.updateOne(
    { actorName: '$actorNameSafe' },
    {
        `$set: { actorShowName: '$heroNameSafe' },
        `$push: { roles: { heroName: '$heroNameSafe', seriesMovieTitle: '$movieSafe', location: '$locationSafe' } }
    }
)
"@

    mongosh $connectionString --quiet --eval $cmd
    Write-Host "Updated $actorName with new role" -ForegroundColor Black -BackgroundColor Yellow
}


function updateSingleValue {
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


function deleteActorByHero {
    param($heroName)
    $heroNameSafe = Escape-Quotes $heroName
    $cmd = @"
db.ActorsData.deleteOne({ 'roles.heroName': '$heroNameSafe' })
"@
    mongosh $connectionString --quiet --eval $cmd
    Write-Host "Deleted role $heroName" -ForegroundColor White -BackgroundColor DarkRed
}

# --------------------------
# Demo Execution
# --------------------------

# Normalize all roles first
Normalize-Roles

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

# Update Matthew Perry's show name
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
