# Read the CSV File
$csvFile = Import-Csv "Movie-Series-Characters.csv"

# 2. Group Rows by Actor Name -> one actor → many roles
# Example: The CSV has 2 rows for Matthew Perry & Kate Beckinsale → They become 1 group.
    # Group: Matthew Perry
    #   Row1: Chandler Bing, Friends, New York
    #   Row2: Ron Clark, The Ron Clark Story, Chicago
    # Group: Kate Beckinsale
    #   Row1: Selene, Underworld, Budapest
    #   Row2: Lori, Total Recall, Calgary
$grouped = $csvFile | Group-Object heroRealName

# 3. Build a MongoDB Document for Each Actor
$documents = foreach ($actor in $grouped) {
    [PSCustomObject]@{
        # $actor.Name is the real actor name -> Eg. Matthew Perry or Kate Beckinsale
        actorName = $actor.Name
        
        # $actor.Group → all rows belonging to the actor
        # Loop through each row and create a role object:

        roles     = $actor.Group | ForEach-Object {
            @{
                heroName         = $_.heroName
                seriesMovieTitle = $_.seriesMovieTitle
                location         = $_.Address
            }
        }

        # For Matthew Perry, this produces:
        # [
        #     {
        #         "heroName": "Chandler Bing",
        #         "seriesMovieTitle": "Friends",
        #         "location": "New York"
        #     },
        #     {
        #         "heroName": "Ron Clark",
        #         "seriesMovieTitle": "The Ron Clark Story",
        #         "location": "Chicago"
        #     }
        # ]

        
    }
}

# 4. Convert the Whole Thing to JSON & Save into a JSON File
# PowerShell needs -Depth 10 because MongoDB JSON has nested arrays

# Without Encoding extra characters found which hampered the import so we use UTF8 here
# $documents | ConvertTo-Json -Depth 10 | Out-File "characterData_mongo.json"
$documents | ConvertTo-Json -Depth 10 | Out-File "characterData_mongo.json" -Encoding UTF8

# 5. Read the JSON File using Out-GridView
$jsonFilePath = "characterData_mongo.json"

$jsonData = Get-Content -Path $jsonFilePath | ConvertFrom-Json

$jsonData | Out-GridView -Title "Actor Data Read from JSON"