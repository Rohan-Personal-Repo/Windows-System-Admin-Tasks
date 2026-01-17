Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# -----------------------------
# MongoDB / Mdbc setup
# -----------------------------
Import-Module Mdbc -ErrorAction Stop

$mongoServer    = $env:MONGO_CONN_STRING
$mongoDatabase  = "ActorsDatabase"
$collectionName = "ActorsData"

if (-not $mongoServer) {
    [System.Windows.Forms.MessageBox]::Show(
        "MONGO_CONN_STRING is not set. Set it before running.",
        "MongoDB Connection Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    return
}

Connect-Mdbc -ConnectionString $mongoServer `
             -DatabaseName $mongoDatabase `
             -CollectionName $collectionName

# Helper to flatten documents into rows for the grid
function Get-FlattenedActors {
    param(
        [string]$heroNameFilter
    )

    if ($heroNameFilter) {
        $actors = Get-MdbcData -Filter @{ heroName = $heroNameFilter } -As PS
    }
    else {
        $actors = Get-MdbcData -As PS
    }

    $rows = New-Object System.Collections.Generic.List[object]

    foreach ($a in $actors) {
        if (-not $a.roles) { continue }

        $roles = if ($a.roles -is [System.Collections.IEnumerable] -and
                     -not ($a.roles -is [string])) {
                     $a.roles
                 } else {
                     @($a.roles)
                 }

        foreach ($r in $roles) {
            $row = [PSCustomObject]@{
                HeroName         = $a.heroName
                RoleName         = $r.roleName
                SeriesMovieTitle = $r.seriesMovieTitle
                Address          = $r.Address
            }
            $rows.Add($row)
        }
    }

    return $rows
}

# -----------------------------
# Windows Forms UI
# -----------------------------

$form               = New-Object System.Windows.Forms.Form
$form.Text          = "Actors Viewer (MongoDB + Mdbc)"
$form.Size          = New-Object System.Drawing.Size(1200, 800)
$form.MinimumSize   = New-Object System.Drawing.Size(1024, 768)
$form.StartPosition = "CenterScreen"
$form.BackColor     = [System.Drawing.Color]::LemonChiffon
$form.Font          = New-Object System.Drawing.Font("Segoe UI", 10)
$form.ForeColor     = [System.Drawing.Color]::Purple

# Tab control
$tabs               = New-Object System.Windows.Forms.TabControl
$tabs.Location      = New-Object System.Drawing.Point(10, 10)
$tabs.Size          = New-Object System.Drawing.Size(1160, 740)
$tabs.Anchor        = "Top,Bottom,Left,Right"

# Tab 1: All Actors
$tabAll             = New-Object System.Windows.Forms.TabPage
$tabAll.Text        = "All Actors"
$tabAll.BackColor   = [System.Drawing.Color]::LemonChiffon

$gridAll            = New-Object System.Windows.Forms.DataGridView
$gridAll.Location   = New-Object System.Drawing.Point(10, 10)
$gridAll.Size       = New-Object System.Drawing.Size(1120, 680)
$gridAll.ReadOnly   = $true
$gridAll.AllowUserToAddRows    = $false
$gridAll.AllowUserToDeleteRows = $false
$gridAll.AutoSizeColumnsMode   = "Fill"
$gridAll.BackgroundColor       = [System.Drawing.Color]::White
$gridAll.Anchor                = "Top,Bottom,Left,Right"

$tabAll.Controls.Add($gridAll)

# Tab 2: Search by heroName
$tabSearch          = New-Object System.Windows.Forms.TabPage
$tabSearch.Text     = "Search by heroName"
$tabSearch.BackColor= [System.Drawing.Color]::LemonChiffon

$lblSearch          = New-Object System.Windows.Forms.Label
$lblSearch.Text     = "Hero Name:"
$lblSearch.Location = New-Object System.Drawing.Point(20, 20)
$lblSearch.AutoSize = $true

$txtSearchHero      = New-Object System.Windows.Forms.TextBox
$txtSearchHero.Location = New-Object System.Drawing.Point(120, 18)
$txtSearchHero.Width    = 300

$btnSearch          = New-Object System.Windows.Forms.Button
$btnSearch.Text     = "Search"
$btnSearch.Location = New-Object System.Drawing.Point(440, 15)
$btnSearch.Size     = New-Object System.Drawing.Size(100, 30)
$btnSearch.BackColor= [System.Drawing.Color]::White

$gridSearch            = New-Object System.Windows.Forms.DataGridView
$gridSearch.Location   = New-Object System.Drawing.Point(10, 60)
$gridSearch.Size       = New-Object System.Drawing.Size(1120, 630)
$gridSearch.ReadOnly   = $true
$gridSearch.AllowUserToAddRows    = $false
$gridSearch.AllowUserToDeleteRows = $false
$gridSearch.AutoSizeColumnsMode   = "Fill"
$gridSearch.BackgroundColor       = [System.Drawing.Color]::White
$gridSearch.Anchor                = "Top,Bottom,Left,Right"

$tabSearch.Controls.AddRange(@(
    $lblSearch, $txtSearchHero, $btnSearch, $gridSearch
))

$tabs.TabPages.AddRange(@($tabAll, $tabSearch))

# -----------------------------
# Load data and wire events
# -----------------------------

# Initial load for All Actors tab
$gridAll.DataSource = Get-FlattenedActors

# Search button: filter by heroName
$btnSearch.Add_Click({
    $hero = $txtSearchHero.Text.Trim()

    if (-not $hero) {
        [System.Windows.Forms.MessageBox]::Show(
            "Enter a heroName to search.",
            "Validation",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }

    $rows = Get-FlattenedActors -heroNameFilter $hero
    $gridSearch.DataSource = $rows

    if ($rows.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "No records found for heroName '$hero'.",
            "Search Result",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
    }
})

# -----------------------------
# Show form
# -----------------------------

[void]$form.Controls.Add($tabs)
[void]$form.ShowDialog()