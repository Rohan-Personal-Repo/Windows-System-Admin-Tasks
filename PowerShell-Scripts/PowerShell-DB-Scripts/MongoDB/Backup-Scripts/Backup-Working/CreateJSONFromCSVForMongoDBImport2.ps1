# Path to your CSV and output JSON
$csvPath  = ".\Movie-Series-Characters.csv"
$jsonPath = ".\Movie-Series-Characters.json"

# Import CSV
$rows = Import-Csv -Path $csvPath

# Transform each row; ensure roles is always an array
$docs = $rows | ForEach-Object {
    [PSCustomObject]@{
        heroId          = [int]$_.heroId
        heroRealName    = $_.heroRealName
        heroName        = $_.heroName
        seriesMovieTitle= $_.seriesMovieTitle
        Address         = $_.Address
        # Initialize roles as an empty array or with default entries if you want
        roles           = @()   # later you can add/remove items in this array in MongoDB
    }
}

# Convert to JSON (MongoDB-friendly JSON array)
$docs | ConvertTo-Json -Depth 5 | Set-Content -Path $jsonPath -Encoding UTF8