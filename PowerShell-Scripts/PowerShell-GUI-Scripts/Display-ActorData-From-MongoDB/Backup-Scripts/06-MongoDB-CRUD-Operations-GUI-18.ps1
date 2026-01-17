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

# ---------------- DATA FLATTENER ----------------
function Get-ActorRows {
    param([string]$HeroFilter)

    if ($HeroFilter) {
        $docs = @(Get-MdbcData -Filter @{
            heroName = @{ '$regex' = $HeroFilter; '$options' = 'i' }
        } -As PS)
    } else {
        $docs = @(Get-MdbcData -As PS)
    }

    $rows = @()

    foreach ($doc in $docs) {
        if (-not $doc.roles) { continue }

        foreach ($role in @($doc.roles)) {
            $rows += [PSCustomObject]@{
                HeroName = $doc.heroName
                Role    = $role.roleName
                Series  = $role.seriesMovieTitle
                Address = $role.Address
            }
        }
    }

    return ,$rows
}

# ---------------- LISTVIEW RENDER ----------------
function Refresh-ListView {
    $list.Items.Clear()

    $totalPages = [Math]::Ceiling($Filtered.Count / $PageSize)
    if ($totalPages -eq 0) { $totalPages = 1 }
    if ($CurrentPage -gt $totalPages) { $CurrentPage = $totalPages }

    $start = ($CurrentPage - 1) * $PageSize
    $page  = $Filtered | Select-Object -Skip $start -First $PageSize

    foreach ($row in $page) {
        $item = New-Object System.Windows.Forms.ListViewItem($row.HeroName)
        $item.SubItems.Add($row.Role)    | Out-Null
        $item.SubItems.Add($row.Series)  | Out-Null
        $item.SubItems.Add($row.Address) | Out-Null
        $list.Items.Add($item) | Out-Null
    }

    $lblPage.Text = "Page $CurrentPage of $totalPages  |  Records: $($Filtered.Count)"
}

# ---------------- UI ----------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Actors Viewer (Table Mode)"
$form.Size = New-Object System.Drawing.Size(1100,600)
$form.StartPosition = "CenterScreen"

$lblSearch = New-Object System.Windows.Forms.Label
$lblSearch.Text = "Live Search (Hero Name):"
$lblSearch.Location = '20,15'

$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Location = '200,12'
$txtSearch.Width = 300

$list = New-Object System.Windows.Forms.ListView
$list.Location = '20,45'
$list.Size = '1040,430'
$list.View = 'Details'
$list.FullRowSelect = $true
$list.GridLines = $true

$list.Columns.Add("Hero Name",200) | Out-Null
$list.Columns.Add("Role",200)      | Out-Null
$list.Columns.Add("Series/Movie",300) | Out-Null
$list.Columns.Add("Address",300)   | Out-Null

$btnPrev = New-Object System.Windows.Forms.Button
$btnPrev.Text = "< Previous"
$btnPrev.Location = '20,490'

$btnNext = New-Object System.Windows.Forms.Button
$btnNext.Text = "Next >"
$btnNext.Location = '140,490'

$lblPage = New-Object System.Windows.Forms.Label
$lblPage.Location = '300,495'
$lblPage.AutoSize = $true

$form.Controls.AddRange(@(
    $lblSearch,$txtSearch,
    $list,$btnPrev,$btnNext,$lblPage
))

# ---------------- EVENTS ----------------

# AUTO LOAD
$form.Add_Shown({
    $AllRows  = Get-ActorRows
    $Filtered = $AllRows
    $CurrentPage = 1
    Refresh-ListView
})

# LIVE SEARCH
$txtSearch.Add_TextChanged({
    $Filtered = Get-ActorRows -HeroFilter $txtSearch.Text.Trim()
    $CurrentPage = 1
    Refresh-ListView
})

# PAGINATION
$btnPrev.Add_Click({
    if ($CurrentPage -gt 1) {
        $CurrentPage--
        Refresh-ListView
    }
})

$btnNext.Add_Click({
    $totalPages = [Math]::Ceiling($Filtered.Count / $PageSize)
    if ($CurrentPage -lt $totalPages) {
        $CurrentPage++
        Refresh-ListView
    }
})

# ---------------- RUN ----------------
[void]$form.ShowDialog()
