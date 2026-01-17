Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Import-Module Mdbc -ErrorAction Stop

# ---------------- MongoDB Connection ----------------
$connectionString = $env:MONGO_CONN_STRING
if (-not $connectionString) {
    [System.Windows.Forms.MessageBox]::Show(
        "MONGO_CONN_STRING environment variable not set",
        "Error",
        "OK",
        "Error"
    ) | Out-Null
    return
}

Connect-Mdbc `
    -ConnectionString $connectionString `
    -DatabaseName "ActorsDatabase" `
    -CollectionName "ActorsData"

# ---------------- Data Loader (FLATTENED, SAFE) ----------------
function Get-ActorRows {
    param([string]$HeroName)

    if ($HeroName) {
        $docs = @(Get-MdbcData -Filter @{ heroName = $HeroName } -As PS)
    } else {
        $docs = @(Get-MdbcData -As PS)
    }

    $rows = @()

    foreach ($doc in $docs) {
        if (-not $doc.roles) { continue }

        foreach ($role in $doc.roles) {
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

# ---------------- UI ----------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Actors Viewer (MongoDB)"
$form.Size = New-Object System.Drawing.Size(1100, 600)
$form.StartPosition = "CenterScreen"

$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Dock = "Fill"

# ================= TAB 1: ALL =================
$tabAll = New-Object System.Windows.Forms.TabPage
$tabAll.Text = "All Actors"

$gridAll = New-Object System.Windows.Forms.DataGridView
$gridAll.Dock = "Fill"
$gridAll.ReadOnly = $true
$gridAll.AutoSizeColumnsMode = "Fill"
$gridAll.AllowUserToAddRows = $false

$tabAll.Controls.Add($gridAll)

# ================= TAB 2: SEARCH =================
$tabSearch = New-Object System.Windows.Forms.TabPage
$tabSearch.Text = "Search"

$lblHero = New-Object System.Windows.Forms.Label
$lblHero.Text = "Hero Name:"
$lblHero.Location = New-Object System.Drawing.Point(20,20)

$txtHero = New-Object System.Windows.Forms.TextBox
$txtHero.Location = New-Object System.Drawing.Point(120,18)
$txtHero.Width = 300

$btnSearch = New-Object System.Windows.Forms.Button
$btnSearch.Text = "Search"
$btnSearch.Location = New-Object System.Drawing.Point(440,16)

$gridSearch = New-Object System.Windows.Forms.DataGridView
$gridSearch.Location = New-Object System.Drawing.Point(20,60)
$gridSearch.Size = New-Object System.Drawing.Size(1000,440)
$gridSearch.ReadOnly = $true
$gridSearch.AutoSizeColumnsMode = "Fill"
$gridSearch.AllowUserToAddRows = $false

$tabSearch.Controls.AddRange(@(
    $lblHero,$txtHero,$btnSearch,$gridSearch
))

# ---------------- Load All Data ----------------
$gridAll.DataSource = Get-ActorRows

# ---------------- Search Event ----------------
$btnSearch.Add_Click({
    $hero = $txtHero.Text.Trim()

    if (-not $hero) {
        [System.Windows.Forms.MessageBox]::Show("Enter a hero name") | Out-Null
        return
    }

    $results = Get-ActorRows -HeroName $hero

    if ($results.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No records found") | Out-Null
        $gridSearch.DataSource = $null
    } else {
        $gridSearch.DataSource = $results
    }
})

# ---------------- Show UI ----------------
$tabs.TabPages.AddRange(@($tabAll,$tabSearch))
$form.Controls.Add($tabs)

[void]$form.ShowDialog()
