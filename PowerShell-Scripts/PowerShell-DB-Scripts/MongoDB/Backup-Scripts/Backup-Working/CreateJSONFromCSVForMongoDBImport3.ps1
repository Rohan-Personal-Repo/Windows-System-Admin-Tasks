# Paths
$csvPath  = ".\Movie-Series-Characters.csv"
$jsonPath = ".\Movie-Series-Characters.json"

# Import CSV (note header is 'herolD' in the sample)
$rows = Import-Csv -Path $csvPath

$docs = $rows | ForEach-Object {
    # # parse/normalize id
    # $id = $_.herolD

    # roles as editable JSON array
    $rolesArray = @()   # or pre-populate if you like

    [PSCustomObject]@{
        # _id              = $id          # MongoDB will use this; no auto _id
        heroRealName     = $_.heroRealName
        heroName         = $_.heroName
        seriesMovieTitle = $_.seriesMovieTitle
        Address          = $_.Address
        roles            = $rolesArray  # always an array
    }
}

$docs | ConvertTo-Json -Depth 5 | Set-Content -Path $jsonPath -Encoding UTF8