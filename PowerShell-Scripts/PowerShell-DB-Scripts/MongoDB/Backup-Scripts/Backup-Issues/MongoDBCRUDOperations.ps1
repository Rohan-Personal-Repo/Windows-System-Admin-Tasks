# --------------------------
# MongoDB connection string
# --------------------------
$connectionString = "mongodb+srv://mongoDBUserName:mongoDBPassword@mongocluster.dev.mongodb.net/"

# --------------------------
# Functions
# --------------------------

function createActor {
    param(
        [string]$actorName,
        [string]$showName,
        [string]$movie,
        [string]$location
    )

    $cmd = @"
db.ActorsData.insertOne({
    actorName: '$actorName',
    actorShowName: '$showName',
    roles: [{ heroName: '$showName', seriesMovieTitle: '$movie', location: '$location' }]
})
"@

    mongosh $connectionString --eval $cmd
    Write-Host "Inserted $actorName" -ForegroundColor White -BackgroundColor DarkGreen
}

function readOneActor {
    param([string]$actorName)

    $cmd = "db.ActorsData.find({ actorName: '$actorName' }).pretty()"
    mongosh $connectionString --eval $cmd
}

function readAllActors {
    $cmd = "db.ActorsData.find({}).map(doc => EJSON.stringify(doc))"
    $jsonOutput = mongosh $connectionString --quiet --eval $cmd

    # Convert each line from JSON to PS object
    $psObjects = $jsonOutput -split "`n" | ForEach-Object { $_ | ConvertFrom-Json }
    $psObjects | Out-GridView -Title "All Actors"
}


function updateMultipleValues {
    param(
        [string]$actorName,
        [string]$heroName,
        [string]$movie,
        [string]$location
    )

    $safeActorName = $actorName.Replace('"','\"')
    $safeHeroName = $heroName.Replace('"','\"')
    $safeMovie = $movie.Replace('"','\"')
    $safeLocation = $location.Replace('"','\"')

    $cmd = @'
db.ActorsData.updateOne(
    { actorName: "' + $safeActorName + '" },
    {
        $set: { actorShowName: "' + $safeHeroName + '" },
        $push: { roles: { heroName: "' + $safeHeroName + '", seriesMovieTitle: "' + $safeMovie + '", location: "' + $safeLocation + '" } }
    }
)
'@

    mongosh $connectionString --eval $cmd
    Write-Host "Updated $actorName" -ForegroundColor Black -BackgroundColor Yellow
}

function updateSingleValue {
    param([string]$newShowName)

    $safeShowName = $newShowName.Replace('"','\"')

    $cmd = @'
db.ActorsData.updateOne(
    { actorName: "Matthew Perry" },
    { $set: { actorShowName: "' + $safeShowName + '" } }
)
'@

    mongosh $connectionString --eval $cmd
    Write-Host "Chandler updated to $newShowName" -ForegroundColor White -BackgroundColor DarkMagenta
}


function deleteActor {
    param([string]$heroName)

    $cmd = "db.ActorsData.deleteOne({ 'roles.heroName': '$heroName' })"
    mongosh $connectionString --eval $cmd
    Write-Host "Deleted role $heroName" -ForegroundColor White -BackgroundColor DarkRed
}

# --------------------------
# Demo: Pass values to functions
# --------------------------

# Insert actors
createActor -actorName "Salma Hayek" -showName "Sonia Kincaid" -movie "Hitmans Wifes Bodyguard" -location "Ottawa"

Write-Host "`n--- Read Kate Beckinsale ---" -ForegroundColor Black -BackgroundColor Cyan
readOneActor -actorName "Kate Beckinsale"

Write-Host "`n--- Read All Actors ---" -ForegroundColor Black -BackgroundColor Cyan
readAllActors

# Update actor
updateMultipleValues -actorName "Matt Leblanc" -heroName "Adam Burns" -movie "Man with a Plan" -location "Vancouver"

# Update Chandler's show name
updateSingleValue -newShowName "Ms. Chanandler Bong"

# Read Matt Leblanc and Matthew Perry after update
Write-Host "`n--- Read Matt Leblanc ---" -ForegroundColor Black -BackgroundColor Cyan
readOneActor -actorName "Matt Leblanc"

Write-Host "`n--- Read Matthew Perry ---" -ForegroundColor Black -BackgroundColor Cyan
readOneActor -actorName "Matthew Perry"

# Delete a role by hero name
deleteActor -heroName "August"

Write-Host "`nDONE!" -ForegroundColor White -BackgroundColor DarkGreen