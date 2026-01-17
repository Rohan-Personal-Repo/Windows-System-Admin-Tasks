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

    # Escape quotes
    $actorName = $actorName.Replace('"','\"')
    $showName = $showName.Replace('"','\"')
    $movie = $movie.Replace('"','\"')
    $location = $location.Replace('"','\"')

    $cmd = @'
db.ActorsData.insertOne({
    actorName: "' + $actorName + '",
    actorShowName: "' + $showName + '",
    roles: [{ heroName: "' + $showName + '", seriesMovieTitle: "' + $movie + '", location: "' + $location + '" }]
})
'@

    mongosh $connectionString --eval $cmd
    Write-Host "Inserted $actorName" -ForegroundColor White -BackgroundColor DarkGreen
}

function readOneActor {
    param([string]$actorName)

    $actorName = $actorName.Replace('"','\"')
    $cmd = 'db.ActorsData.find({ actorName: "' + $actorName + '" }).forEach(doc => print(JSON.stringify(doc)))'
    $output = mongosh $connectionString --quiet --eval $cmd

    # Display output line by line
    $output -split "`n" | ForEach-Object { Write-Host $_ -ForegroundColor Cyan }
}

function readAllActors {
    $cmd = 'db.ActorsData.find({}).forEach(doc => print(JSON.stringify(doc)))'
    $output = mongosh $connectionString --quiet --eval $cmd

    # Split lines into Out-GridView
    $output -split "`n" | Out-GridView -Title "All Actors"
}

function updateMultipleValues {
    param(
        [string]$actorName,
        [string]$heroName,
        [string]$movie,
        [string]$location
    )

    # Escape quotes
    $actorName = $actorName.Replace('"','\"')
    $heroName = $heroName.Replace('"','\"')
    $movie = $movie.Replace('"','\"')
    $location = $location.Replace('"','\"')

    $cmd = @'
db.ActorsData.updateOne(
    { actorName: "' + $actorName + '" },
    {
        $set: { actorShowName: "' + $heroName + '" },
        $push: { roles: { heroName: "' + $heroName + '", seriesMovieTitle: "' + $movie + '", location: "' + $location + '" } }
    }
)
'@

    mongosh $connectionString --eval $cmd
    Write-Host "Updated $actorName" -ForegroundColor Black -BackgroundColor Yellow
}

function updateSingleValue {
    param([string]$actorName,[string]$newShowName)

    # Escape quotes
    $actorName = $actorName.Replace('"','\"')
    $newShowName = $newShowName.Replace('"','\"')

    $cmd = @'
db.ActorsData.updateOne(
    { actorName: "' + $actorName + '" },
    { $set: { actorShowName: "' + $newShowName + '" } }
)
'@

    mongosh $connectionString --eval $cmd
    Write-Host "$actorName updated to $newShowName" -ForegroundColor White -BackgroundColor DarkMagenta
}

function deleteActorByHero {
    param([string]$heroName)

    $heroName = $heroName.Replace('"','\"')
    $cmd = 'db.ActorsData.deleteOne({ "roles.heroName": "' + $heroName + '" })'
    mongosh $connectionString --eval $cmd
    Write-Host "Deleted role $heroName" -ForegroundColor White -BackgroundColor DarkRed
}

# --------------------------
# Demo: CRUD operations
# --------------------------

# 1️⃣ Insert actors
createActor -actorName "Salma Hayek" -showName "Sonia Kincaid" -movie "Hitmans Wifes Bodyguard" -location "Ottawa"
createActor -actorName "Matthew Perry" -showName "Chandler Bing" -movie "Friends" -location "New York"
createActor -actorName "Matt Leblanc" -showName "Joey Tribbiani" -movie "Friends" -location "Rome"

# 2️⃣ Read one actor
Write-Host "`n--- Read Kate Beckinsale ---" -ForegroundColor Black -BackgroundColor Cyan
readOneActor -actorName "Kate Beckinsale"

# 3️⃣ Read all actors
Write-Host "`n--- Read All Actors ---" -ForegroundColor Black -BackgroundColor Cyan
readAllActors

# 4️⃣ Update actor
updateMultipleValues -actorName "Matt Leblanc" -heroName "Adam Burns" -movie "Man with a Plan" -location "Vancouver"

# 5️⃣ Update Chandler's show name
updateSingleValue -actorName "Matthew Perry" -newShowName "Ms. Chanandler Bong"

# 6️⃣ Read updated actors
Write-Host "`n--- Read Matt Leblanc ---" -ForegroundColor Black -BackgroundColor Cyan
readOneActor -actorName "Matt Leblanc"

Write-Host "`n--- Read Matthew Perry ---" -ForegroundColor Black -BackgroundColor Cyan
readOneActor -actorName "Matthew Perry"

# 7️⃣ Delete a role by hero name
deleteActorByHero -heroName "August"

Write-Host "`nDONE!" -ForegroundColor White -BackgroundColor DarkGreen
