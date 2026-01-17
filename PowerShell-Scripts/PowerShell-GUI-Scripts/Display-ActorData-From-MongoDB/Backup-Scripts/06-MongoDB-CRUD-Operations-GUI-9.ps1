Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Import-Module Mdbc -ErrorAction Stop

# ---------- MongoDB connection ----------
$mongoServer    = $env:MONGO_CONN_STRING
$mongoDatabase  = "ActorsDatabase"
$collectionName = "ActorsData"

if (-not $mongoServer) {
    [System.Windows.Forms.MessageBox]::Show("MONGO_CONN_STRING not set.","Error") | Out-Null
    return
}

Connect-Mdbc -ConnectionString $mongoServer `
             -DatabaseName $mongoDatabase `
             -CollectionName $collectionName

# ---------- Data helper ----------
function Get-FlattenedActors {
    param([string]$heroNameFilter)

    if ($heroNameFilter) {
        $actors = Get-MdbcData -Filter @{ heroName = $heroNameFilter } -As PS
    } else {
        $actors = Get-MdbcData -As PS
    }

    $rows = New-Object System.Collections.Generic.List[object]

    foreach ($a in $actors) {
        if (-not $a.roles) { continue }

        $roles = if ($a.roles -is [System.Collections.IEnumerable] -and
                     -not ($a.roles -is [string])) { $a.roles } else { @($a.roles) }

        foreach ($r in $roles) {
            $rows.Add([PSCustomObject]@{
                HeroName         = $a.heroName
                RoleName         = $r.roleName
                SeriesMovieTitle = $r.seriesMovieTitle
                Address          = $r.Address
            })
        }
    }

    return $rows
}

# ---------- UI ----------
$form               = New-Object System.Windows.Forms.Form
$form.Text          = "Actors Viewer (MongoDB + Mdbc)"
$form.Size          = New-Object System.Drawing.Size(1200, 800)
$form.MinimumSize   = New-Object System.Drawing.Size(1024, 768)
$form.StartPosition = "CenterScreen"
$form.BackColor     = [System.Drawing.Color]::LemonChiffon
$form.Font          = New-Object System.Drawing.Font("Segoe UI", 10)
$form.ForeColor     = [System.Drawing.Color]::Purple

$tabs               = New-Object System.Windows.Forms.TabControl
$tabs.Location      = New-Object System.Drawing.Point(10, 10)
$tabs.Size          = New-Object System.Drawing.Size(1160, 740)
$tabs.Anchor        = "Top,Bottom,Left,Right"

# --- Shared details panel (labels) ---
$detailsPanel              = New-Object System.Windows.Forms.Panel
$detailsPanel.Height       = 80
$detailsPanel.Dock         = "Bottom"
$detailsPanel.BackColor    = [System.Drawing.Color]::LemonChiffon

$lblHeroCaption            = New-Object System.Windows.Forms.Label
$lblHeroCaption.Text       = "Hero:"
$lblHeroCaption.Location   = New-Object System.Drawing.Point(10, 10)
$lblHeroCaption.AutoSize   = $true

$lblHeroValue              = New-Object System.Windows.Forms.Label
$lblHeroValue.Location     = New-Object System.Drawing.Point(70, 10)
$lblHeroValue.AutoSize     = $true

$lblRoleCaption            = New-Object System.Windows.Forms.Label
$lblRoleCaption.Text       = "Role:"
$lblRoleCaption.Location   = New-Object System.Drawing.Point(10, 35)
$lblRoleCaption.AutoSize   = $true

$lblRoleValue              = New-Object System.Windows.Forms.Label
$lblRoleValue.Location     = New-Object System.Drawing.Point(70, 35)
$lblRoleValue.AutoSize     = $true

$lblSeriesCaption          = New-Object System.Windows.Forms.Label
$lblSeriesCaption.Text     = "Series/Movie:"
$lblSeriesCaption.Location = New-Object System.Drawing.Point(350, 10)
$lblSeriesCaption.AutoSize = $true

$lblSeriesValue            = New-Object System.Windows.Forms.Label
$lblSeriesValue.Location   = New-Object System.Drawing.Point(460, 10)
$lblSeriesValue.AutoSize   = $true

$lblAddressCaption          = New-Object System.Windows.Forms.Label
$lblAddressCaption.Text     = "Address:"
$lblAddressCaption.Location = New-Object System.Drawing.Point(350, 35)
$lblAddressCaption.AutoSize = $true

$lblAddressValue            = New-Object System.Windows.Forms.Label
$lblAddressValue.Location   = New-Object System.Drawing.Point(460, 35)
$lblAddressValue.AutoSize   = $true

$detailsPanel.Controls.AddRange(@(
    $lblHeroCaption,$lblHeroValue,
    $lblRoleCaption,$lblRoleValue,
    $lblSeriesCaption,$lblSeriesValue,
    $lblAddressCaption,$lblAddressValue
))

# Helper to update labels from a row
function Set-DetailsFromRow {
    param($row)

    if (-not $row) {
        $lblHeroValue.Text    = ""
        $lblRoleValue.Text    = ""
        $lblSeriesValue.Text  = ""
        $lblAddressValue.Text = ""
        return
    }

    $lblHeroValue.Text    = [string]$row.Cells["HeroName"].Value
    $lblRoleValue.Text    = [string]$row.Cells["RoleName"].Value
    $lblSeriesValue.Text  = [string]$row.Cells["SeriesMovieTitle"].Value
    $lblAddressValue.Text = [string]$row.Cells["Address"].Value
}

# --- Tab: All Actors ---
$tabAll           = New-Object System.Windows.Forms.TabPage
$tabAll.Text      = "All Actors"
$tabAll.BackColor = [System.Drawing.Color]::LemonChiffon

$btnAllReload          = New-Object System.Windows.Forms.Button
$btnAllReload.Text     = "Reload All"
$btnAllReload.Location = New-Object System.Drawing.Point(10, 10)
$btnAllReload.Size     = New-Object System.Drawing.Size(120, 30)
$btnAllReload.BackColor= [System.Drawing.Color]::White

$gridAll               = New-Object System.Windows.Forms.DataGridView
$gridAll.Location      = New-Object System.Drawing.Point(10, 50)
$gridAll.Size          = New-Object System.Drawing.Size(1120, 580)
$gridAll.ReadOnly      = $true
$gridAll.AllowUserToAddRows    = $false
$gridAll.AllowUserToDeleteRows = $false
$gridAll.AutoSizeColumnsMode   = "Fill"
$gridAll.BackgroundColor       = [System.Drawing.Color]::White
$gridAll.Anchor                = "Top,Bottom,Left,Right"

# add grid + details panel inside this tab
$tabAll.Controls.AddRange(@($btnAllReload,$gridAll,$detailsPanel))

# --- Tab: Search by heroName ---
$tabSearch           = New-Object System.Windows.Forms.TabPage
$tabSearch.Text      = "Search by heroName"
$tabSearch.BackColor = [System.Drawing.Color]::LemonChiffon

$lblSearch          = New-Object System.Windows.Forms.Label
$lblSearch.Text     = "Hero Name:"
$lblSearch.Location = New-Object System.Drawing.Point(20, 20)
$lblSearch.AutoSize = $true

$txtSearchHero          = New-Object System.Windows.Forms.TextBox
$txtSearchHero.Location = New-Object System.Drawing.Point(120, 18)
$txtSearchHero.Width    = 300

$btnSearch          = New-Object System.Windows.Forms.Button
$btnSearch.Text     = "Search"
$btnSearch.Location = New-Object System.Drawing.Point(440, 15)
$btnSearch.Size     = New-Object System.Drawing.Size(100, 30)
$btnSearch.BackColor= [System.Drawing.Color]::White

$gridSearch            = New-Object System.Windows.Forms.DataGridView
$gridSearch.Location   = New-Object System.Drawing.Point(10, 60)
$gridSearch.Size       = New-Object System.Drawing.Size(1120, 580)
$gridSearch.ReadOnly   = $true
$gridSearch.AllowUserToAddRows    = $false
$gridSearch.AllowUserToDeleteRows = $false
$gridSearch.AutoSizeColumnsMode   = "Fill"
$gridSearch.BackgroundColor       = [System.Drawing.Color]::White
$gridSearch.Anchor                = "Top,Bottom,Left,Right"

$tabSearch.Controls.AddRange(@(
    $lblSearch,$txtSearchHero,$btnSearch,$gridSearch,$detailsPanel
))

$tabs.TabPages.AddRange(@($tabAll,$tabSearch))
$form.Controls.Add($tabs)

# ---------- Events ----------
$btnAllReload.Add_Click({
    $rows = Get-FlattenedActors
    $gridAll.DataSource = $null
    $gridAll.DataSource = $rows
    if ($gridAll.Rows.Count -gt 0) {
        Set-DetailsFromRow $gridAll.Rows[0]
    } else {
        Set-DetailsFromRow $null
    }
})

$btnSearch.Add_Click({
    $hero = $txtSearchHero.Text.Trim()
    if (-not $hero) {
        [System.Windows.Forms.MessageBox]::Show("Enter a heroName to search.","Info") | Out-Null
        return
    }
    $rows = Get-FlattenedActors -heroNameFilter $hero
    $gridSearch.DataSource = $null
    $gridSearch.DataSource = $rows
    if ($gridSearch.Rows.Count -gt 0) {
        Set-DetailsFromRow $gridSearch.Rows[0]
    } else {
        Set-DetailsFromRow $null
        [System.Windows.Forms.MessageBox]::Show("No records found for heroName '$hero'.","Info") | Out-Null
    }
})

# row click -> update labels
$gridAll.Add_CellClick({
    param($sender,$e)
    if ($e.RowIndex -lt 0) { return }
    Set-DetailsFromRow $gridAll.Rows[$e.RowIndex]
})

$gridSearch.Add_CellClick({
    param($sender,$e)
    if ($e.RowIndex -lt 0) { return }
    Set-DetailsFromRow $gridSearch.Rows[$e.RowIndex]
})

# initial load
$btnAllReload.PerformClick()

[void]$form.ShowDialog()
