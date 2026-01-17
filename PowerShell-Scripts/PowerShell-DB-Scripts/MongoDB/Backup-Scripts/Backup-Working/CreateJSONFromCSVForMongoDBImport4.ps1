# Paths
$csvPath  = ".\Movie-Series-Characters.csv"
$jsonPath = ".\Movie-Series-Characters.json"

# Import CSV
$rows = Import-Csv -Path $csvPath

$docs = $rows | ForEach-Object {

    # Build roles array with one object per row
    $rolesArray = @(
        [PSCustomObject]@{
            roleName        = $_.heroName          # character name
            seriesMovieTitle= $_.seriesMovieTitle  # show/movie
            Address         = $_.Address           # location
        }
    )

    # Document structure for MongoDB (no _id, no heroId)
    [PSCustomObject]@{
        actorName = $_.heroRealName
        roles     = $rolesArray   # JSON array; can add/remove objects later
    }
}

# Export as JSON array
$docs | ConvertTo-Json -Depth 5 | Set-Content -Path $jsonPath -Encoding UTF8
