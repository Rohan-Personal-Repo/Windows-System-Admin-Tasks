# Paths
$csvPath  = ".\Data\Movie-Series-Characters.csv"
$jsonPath = ".\Data\Movie-Series-Characters.json"

# Import CSV
$rows = Import-Csv -Path $csvPath

# Group by actor (heroRealName)
$grouped = $rows | Group-Object -Property heroRealName

$docs = $grouped | ForEach-Object {
    $actorName = $_.Name

    # Build roles array for this actor (one object per CSV row)
    $rolesArray = @()
    foreach ($r in $_.Group) {
        $rolesArray += [PSCustomObject]@{
            roleName         = $r.heroName
            seriesMovieTitle = $r.seriesMovieTitle
            Address          = $r.Address
        }
    }

    # Final document for this actor
    [PSCustomObject]@{
        heroName = $actorName     # actor name
        roles    = $rolesArray    # array with 1..n role objects
    }
}

# Export as JSON array for mongoimport
$docs | ConvertTo-Json -Depth 5 | Set-Content -Path $jsonPath -Encoding UTF8

Write-Host "`n--- Successfully Converted CSV to JSON ---" -ForegroundColor DarkRed -BackgroundColor Yellow