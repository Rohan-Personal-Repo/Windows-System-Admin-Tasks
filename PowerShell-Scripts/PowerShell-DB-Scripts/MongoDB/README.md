# MongoDB Actors – PowerShell 7 + Mdbc 7

PowerShell 7 + Mdbc 7 scripts to load actor data into MongoDB, perform CRUD, and visualize it with a WinForms Live Search viewer.

---

## 1. Setup

- Install MongoDB and `Mdbc` v7.  
- Create `MONGO_CONN_STRING` pointing to your MongoDB connection string (via OS tools or `Environment.SetEnvironmentVariable`), then restart PowerShell 7 and verify with:

$env:MONGO_CONN_STRING


---

## 2. Convert CSV to nested JSON

- **Script:** `Convert-Csv-To-Json.ps1`  
- **Input:** `.\Data\Movie-Series-Characters.csv`  
- **Output:** `.\Data\Movie-Series-Characters.json`  

Steps:

- Import CSV, group by `heroRealName` (actor).  
- Build one document per actor with a `roles` array (`roleName`, `seriesMovieTitle`, `Address`).  
- Export as a JSON array ready for MongoDB.

---

## 3. Import JSON into MongoDB

- **Script:** `Import-Json-To-Mongo.ps1`  
- **DB:** `ActorsDatabase`  
- **Collection:** `ActorsData`  

Steps:

- `Connect-Mdbc` using `$env:MONGO_CONN_STRING`.  
- Load `Movie-Series-Characters.json` and pipe to `Add-MdbcData -Many`.  
- Verify document count and preview with `Out-GridView`.

---

## 4. CRUD scripts (`Actors-CRUD.ps1`)

Working against documents like:

{
    "heroName": "Kate Beckinsale",
    "roles": [
      {
        "roleName": "Selene",
        "seriesMovieTitle": "Underworld",
        "Address": "Budapest"
      },
      {
        "roleName": "Lori",
        "seriesMovieTitle": "Total Recall",
        "Address": "Calgary"
      }
    ]
}


### Functions

- **`updateMultipleValues`**  
  - If `heroName` exists: `$push` a new role into `roles`.  
  - Else: create a new document with `roles` as a one‑element array.

- **`readOneActor` / `readAllActors`**  
  - Query actors, flatten `roles` to rows (`ActorName`, `RoleName`, `SeriesMovieTitle`, `Location`), display with `Out-GridView`.

- **`updateSingleValue`**  
  - Filter by `heroName` + `roles.roleName` and rename one role using `$set` with the positional operator.

- **`deleteActorByHero`**  
  - `$pull` roles with a given `roleName`, keeping the actor document.

Demo calls show adding roles (e.g. Salma Hayek), appending for Matt LeBlanc, renaming “Chandler Bing” to “Ms. Chanandler Bong”, and deleting a role named “August”.

---

## 5. WinForms Live Search viewer

- **Script:** `Under PowerShell-GUI-Scripts Folder: 03-Display-MongoDB-Data-GUI.ps1`  

Features:

- Connects via `$env:MONGO_CONN_STRING` and Mdbc 7 to `ActorsDatabase.ActorsData`.  
- Loads actors + roles into a multi‑column `ListView` with widened, auto‑sized columns for long names.  
- Live search textbox filters by `heroName` as you type.  
- Light/Dark buttons recolor form, labels, search box, and ListView while keeping data intact.

## 6. Resources:
- [SET PS Environment Variable](https://learn.microsoft.com/en-us/dotnet/api/system.environment.setenvironmentvariable?view=net-10.0)
- [Install MDBC](https://www.powershellgallery.com/packages/Mdbc/7.0.1)
- [Install PowerShell7](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows?view=powershell-7.5)