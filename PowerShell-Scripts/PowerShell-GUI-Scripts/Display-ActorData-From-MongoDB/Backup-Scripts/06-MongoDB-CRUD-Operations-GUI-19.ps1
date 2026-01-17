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
$PageSize    = 12
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
    $list.BeginUpdate()
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

    $lblPage.Text = "Page $CurrentPage of $totalPages   |   Records: $($Filtered.Count)"
    $list.EndUpdate()
}

# ---------------- DARK THEME COLORS ----------------
$bgForm   = [System.Drawing.Color]::FromArgb(32,32,32)
$bgPanel  = [System.Drawing.Color]::FromArgb(45,45,48)
$fgText   = [System.Drawing.Color]::Gainsboro
$accent   = [System.Drawing.Color]::FromArgb(0,122,204)

# ---------------- UI ----------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Actors Viewer — Dark Mode"
$form.Size = New-Object System.Drawing.Size(1300,700)
$form.StartPosition = "CenterScreen"
$form.BackColor = $bgForm
$form.ForeColor = $fgText
$form.Font = New-Object System.Drawing.Font("Segoe UI",11)

$lblSearch = New-Object System.Windows.Forms.Label
$lblSearch.Text = "Live Search (Hero Name):"
$lblSearch.Location = '20,20'
$lblSearch.ForeColor = $fgText

$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Location = '230,18'
$txtSearch.Width = 350
$txtSearch.BackColor = $bgPanel
$txtSearch.ForeColor = $fgText
$txtSearch.BorderStyle = 'FixedSingle'

$list = New-Object System.Windows.Forms.ListView
$list.Location = '20,60'
$list.Size = '1240,500'
$list.View = 'Details'
$list.FullRowSelect = $true
$list.GridLines = $true
$list.HideSelection = $false
$list.BackColor = $bgPanel
$list.ForeColor = $fgText
$list.Font = New-Object System.Drawing.Font("Segoe UI",11)

$list.Columns.Add("Hero Name",260) | Out-Null
$list.Columns.Add("Role",260)      | Out-Null
$list.Columns.Add("Series / Movie",360) | Out-Null
$list.Columns.Add("Address",360)   | Out-Null

$btnPrev = New-Object System.Windows.Forms.Button
$btnPrev.Text = "< Previous"
$btnPrev.Location = '20,580'
$btnPrev.Size = '120,40'
$btnPrev.BackColor = $accent
$btnPrev.ForeColor = 'White'
$btnPrev.FlatStyle = 'Flat'

$btnNext = New-Object System.Windows.Forms.Button
$btnNext.Text = "Next >"
$btnNext.Location = '160,580'
$btnNext.Size = '120,40'
$btnNext.BackColor = $accent
$btnNext.ForeColor = 'White'
$btnNext.FlatStyle = 'Flat'

$lblPage = New-Object System.Windows.Forms.Label
$lblPage.Location = '320,590'
$lblPage.AutoSize = $true
$lblPage.ForeColor = $fgText

$form.Controls.AddRange(@(
    $lblSearch,$txtSearch,
    $list,$btnPrev,$btnNext,$lblPage
))

# ---------------- EVENTS ----------------
$form.Add_Shown({
    $AllRows = Get-ActorRows
    $Filtered = $AllRows
    $CurrentPage = 1
    Refresh-ListView
})

$txtSearch.Add_TextChanged({
    $Filtered = Get-ActorRows -HeroFilter $txtSearch.Text.Trim()
    $CurrentPage = 1
    Refresh-ListView
})

$btnPrev.Add_Click({
    if ($CurrentPage -gt 1) {
        $CurrentPage--
        Refresh-ListView
    }
})

$btnNext.Add_Click({
    $max = [Math]::Ceiling($Filtered.Count / $PageSize)
    if ($CurrentPage -lt $max) {
        $CurrentPage++
        Refresh-ListView
    }
})

# ---------------- RUN ----------------
[void]$form.ShowDialog()
