Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Import-Module Mdbc -ErrorAction Stop

# ---------------- MongoDB ----------------
$mongoConn = $env:MONGO_CONN_STRING
if (-not $mongoConn) {
    [System.Windows.Forms.MessageBox]::Show("MONGO_CONN_STRING not set","Error") | Out-Null
    return
}

Connect-Mdbc -ConnectionString $mongoConn `
             -DatabaseName "ActorsDatabase" `
             -CollectionName "ActorsData"

# ---------------- GLOBAL STATE ----------------
$PageSize    = 10
$CurrentPage = 1
$AllRows     = @()
$Filtered    = @()

# ---------------- DATA NORMALIZER ----------------
function Get-ActorRows {
    param([string]$HeroFilter)

    if ($HeroFilter) {
        $docs = @(Get-MdbcData -Filter @{ heroName = @{ '$regex' = $HeroFilter; '$options' = 'i' } } -As PS)
    } else {
        $docs = @(Get-MdbcData -As PS)
    }

    $rows = @()

    foreach ($doc in $docs) {
        foreach ($role in @($doc.roles)) {
            $rows += [PSCustomObject]@{
                HeroName = $doc.heroName
                RoleName = $role.roleName
                Series   = $role.seriesMovieTitle
                Address  = $role.Address
            }
        }
    }

    return ,$rows
}

# ---------------- PAGINATION ----------------
function Refresh-Grid {
    $totalPages = [Math]::Ceiling($Filtered.Count / $PageSize)
    if ($totalPages -eq 0) { $totalPages = 1 }
    if ($CurrentPage -gt $totalPages) { $CurrentPage = $totalPages }

    $start = ($CurrentPage - 1) * $PageSize
    $page  = $Filtered | Select-Object -Skip $start -First $PageSize

    $grid.DataSource = $null
    $grid.DataSource = $page

    $lblPage.Text = "Page $CurrentPage of $totalPages"
}

# ---------------- UI ----------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Actors Viewer"
$form.Size = New-Object System.Drawing.Size(1100,600)
$form.StartPosition = "CenterScreen"

$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Location = '20,15'
$txtSearch.Width = 300

$lblSearch = New-Object System.Windows.Forms.Label
$lblSearch.Text = "Live Search (Hero Name):"
$lblSearch.Location = '20,45'

$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = '20,70'
$grid.Size = '1040,420'
$grid.ReadOnly = $true
$grid.AutoSizeColumnsMode = 'Fill'
$grid.SelectionMode = 'FullRowSelect'

$btnPrev = New-Object System.Windows.Forms.Button
$btnPrev.Text = "< Previous"
$btnPrev.Location = '20,510'

$btnNext = New-Object System.Windows.Forms.Button
$btnNext.Text = "Next >"
$btnNext.Location = '140,510'

$lblPage = New-Object System.Windows.Forms.Label
$lblPage.Location = '280,515'
$lblPage.AutoSize = $true

$form.Controls.AddRange(@(
    $txtSearch,$lblSearch,
    $grid,$btnPrev,$btnNext,$lblPage
))

# ---------------- EVENTS ----------------

# AUTO LOAD
$form.Add_Shown({
    $AllRows  = Get-ActorRows
    $Filtered = $AllRows
    $CurrentPage = 1
    Refresh-Grid
})

# LIVE SEARCH
$txtSearch.Add_TextChanged({
    $Filtered = Get-ActorRows -HeroFilter $txtSearch.Text.Trim()
    $CurrentPage = 1
    Refresh-Grid
})

# PREVIOUS PAGE
$btnPrev.Add_Click({
    if ($CurrentPage -gt 1) {
        $CurrentPage--
        Refresh-Grid
    }
})

# NEXT PAGE
$btnNext.Add_Click({
    $totalPages = [Math]::Ceiling($Filtered.Count / $PageSize)
    if ($CurrentPage -lt $totalPages) {
        $CurrentPage++
        Refresh-Grid
    }
})

# ---------------- RUN ----------------
[void]$form.ShowDialog()
