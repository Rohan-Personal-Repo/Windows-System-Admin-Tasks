# Create a CLIXML file for the Password and get credentials from that XML file
# $credentials = Get-Credential -Message "MongoDB Password" -UserName "mongodbAdmin"
# $credentials | Export-Clixml -Path ".\creds.xml"
# Write-Output "UserName :  $credentials.UserName  and Password :  $credentials.Password "

# $mongoPwd = Import-Clixml -Path ".\creds.xml"

Connect-Mdbc -ConnectionString "mongodb+srv://mongoDBUserName:mongoDBPassword@mongocluster.dev.mongodb.net/"

$actorDB = Get-MdbcDatabase -Name "ActorsDatabase" 

$actorData = Get-MdbcCollection -Name "ActorsData" -Database $actorDB

$actors = Get-MdbcData -Collection $actorData

Write-Host "Actors Data: " -BackgroundColor Black -ForegroundColor Cyan
# Write-Output $actors
# $actors | Out-GridView -Title "Actor Data"
# Connect-Mdbc -ConnectionString 

# Flatten roles for display
$flattenedActors = foreach ($actor in $actors) {
    if ($actor.roles -is [System.Array]) {
        # Multiple roles
        foreach ($role in $actor.roles) {
            [PSCustomObject]@{
                ActorName        = $actor.actorName
                HeroName         = $role.heroName
                SeriesMovieTitle = $role.seriesMovieTitle
                Location         = $role.location
            }
        }
    } else {
        # Single role object
        [PSCustomObject]@{
            ActorName        = $actor.actorName
            HeroName         = $actor.roles.heroName
            SeriesMovieTitle = $actor.roles.seriesMovieTitle
            Location         = $actor.roles.location
        }
    }
}

# Display nicely in Out-GridView
$flattenedActors | Out-GridView -Title "ActorsData Collection"