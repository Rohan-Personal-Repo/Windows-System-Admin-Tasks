Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Import-Module Mdbc -ErrorAction Stop

# ---------------- MongoDB ----------------
Connect-Mdbc -ConnectionString $env:MONGO_CONN_STRING `
             -DatabaseName "ActorsDatabase" `
             -CollectionName "ActorsData"

# ---------------- DATA ----------------
$PageSize    = 10
$CurrentPage = 1
$AllRows     = @()
$Filtered    = @()

function Get-ActorRows {
    param([string]$filter)

    if ($filter) {
        $docs = @(Get-MdbcData -Filter @{
            heroName = @{ '$regex' = $filter; '$options' = 'i' }
        } -As PS)
    } else {
        $docs = @(Get-MdbcData -As PS)
    }

    $rows = @()
    foreach ($d in $docs) {
        foreach ($r in @($d.roles)) {
            $rows += [PSCustomObject]@{
                Hero    = $d.heroName
                Role    = $r.roleName
                Series  = $r.seriesMovieTitle
                Address = $r.Address
            }
        }
    }
    return ,$rows
}

function Refresh-List {
    $list.Items.Clear()

    $totalPages = [Math]::Max(1,[Math]::Ceiling($Filtered.Count/$PageSize))
    if ($CurrentPage -gt $totalPages) { $CurrentPage = $totalPages }

    $start = ($CurrentPage-1)*$PageSize
    $page  = $Filtered | Select-Object -Skip $start -First $PageSize

    foreach ($row in $page) {
        $i = New-Object System.Windows.Forms.ListViewItem($row.Hero)
        $i.SubItems.Add($row.Role)    | Out-Null
        $i.SubItems.Add($row.Series)  | Out-Null
        $i.SubItems.Add($row.Address) | Out-Null
        $list.Items.Add($i) | Out-Null
    }

    $lblPage.Text = "Page $CurrentPage of $totalPages  |  Records: $($Filtered.Count)"
    $list.AutoResizeColumns('ColumnContent')
}

# ---------------- THEMES ----------------
function Apply-LightTheme {
    $form.BackColor = 'LemonChiffon'
    $form.ForeColor = 'Purple'
    $topPanel.BackColor = 'LemonChiffon'
    $list.BackColor = 'White'
    $list.ForeColor = 'Purple'
    $txtSearch.BackColor = 'White'
    $txtSearch.ForeColor = 'Purple'
}

function Apply-DarkTheme {
    $form.BackColor = 'Black'
    $form.ForeColor = 'Aquamarine'
    $topPanel.BackColor = 'Black'
    $list.BackColor = 'Black'
    $list.ForeColor = 'Aquamarine'
    $txtSearch.BackColor = '#1e1e1e'
    $txtSearch.ForeColor = 'Aquamarine'
}

# ---------------- UI ----------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Actors Viewer — Multi Theme"
$form.Size = '1400,750'
$form.StartPosition = 'CenterScreen'

# Top panel (SEARCH + THEME)
$topPanel = New-Object System.Windows.Forms.Panel
$topPanel.Dock = 'Top'
$topPanel.Height = 60

$lblSearch = New-Object System.Windows.Forms.Label
$lblSearch.Text = "Live Search (Hero Name):"
$lblSearch.Location = '20,18'
$lblSearch.AutoSize = $true

$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Location = '230,15'
$txtSearch.Width = 350

$btnLight = New-Object System.Windows.Forms.Button
$btnLight.Text = "Light Theme"
$btnLight.Location = '620,12'
$btnLight.Size = '110,35'

$btnDark = New-Object System.Windows.Forms.Button
$btnDark.Text = "Dark Theme"
$btnDark.Location = '750,12'
$btnDark.Size = '110,35'

$topPanel.Controls.AddRange(@($lblSearch,$txtSearch,$btnLight,$btnDark))
$form.Controls.Add($topPanel)

# ListView
$list = New-Object System.Windows.Forms.ListView
$list.Dock = 'Fill'
$list.View = 'Details'
$list.FullRowSelect = $true
$list.GridLines = $true
$list.Font = New-Object System.Drawing.Font("Segoe UI",12)

$list.Columns.Add("Hero Name",300) | Out-Null
$list.Columns.Add("Role",300)      | Out-Null
$list.Columns.Add("Series / Movie",400) | Out-Null
$list.Columns.Add("Address",300)   | Out-Null

$form.Controls.Add($list)

# Bottom panel (pagination)
$bottom = New-Object System.Windows.Forms.Panel
$bottom.Dock = 'Bottom'
$bottom.Height = 60

$btnPrev = New-Object System.Windows.Forms.Button
$btnPrev.Text = "< Previous"
$btnPrev.Location = '20,12'
$btnPrev.Size = '120,35'

$btnNext = New-Object System.Windows.Forms.Button
$btnNext.Text = "Next >"
$btnNext.Location = '160,12'
$btnNext.Size = '120,35'

$lblPage = New-Object System.Windows.Forms.Label
$lblPage.Location = '320,18'
$lblPage.AutoSize = $true

$bottom.Controls.AddRange(@($btnPrev,$btnNext,$lblPage))
$form.Controls.Add($bottom)

# ---------------- EVENTS ----------------
$form.Add_Shown({
    $AllRows = Get-ActorRows
    $Filtered = $AllRows
    Apply-DarkTheme
    Refresh-List
})

$txtSearch.Add_TextChanged({
    $Filtered = Get-ActorRows $txtSearch.Text.Trim()
    $CurrentPage = 1
    Refresh-List
})

$btnPrev.Add_Click({
    if ($CurrentPage -gt 1) {
        $CurrentPage--
        Refresh-List
    }
})

$btnNext.Add_Click({
    $max = [Math]::Ceiling($Filtered.Count/$PageSize)
    if ($CurrentPage -lt $max) {
        $CurrentPage++
        Refresh-List
    }
})

$btnLight.Add_Click({ Apply-LightTheme })
$btnDark.Add_Click({ Apply-DarkTheme })

# ---------------- RUN ----------------
[void]$form.ShowDialog()
