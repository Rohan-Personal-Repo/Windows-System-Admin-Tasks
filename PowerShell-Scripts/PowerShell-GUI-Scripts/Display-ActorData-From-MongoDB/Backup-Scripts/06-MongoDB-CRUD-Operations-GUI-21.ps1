Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Import-Module Mdbc -ErrorAction Stop

# ---------------- MongoDB ----------------
Connect-Mdbc -ConnectionString $env:MONGO_CONN_STRING `
             -DatabaseName "ActorsDatabase" `
             -CollectionName "ActorsData"

# ---------------- DATA ----------------
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

function Load-List($rows) {
    $list.Items.Clear()
    foreach ($row in $rows) {
        $i = New-Object System.Windows.Forms.ListViewItem($row.Hero)
        $i.SubItems.Add($row.Role)    | Out-Null
        $i.SubItems.Add($row.Series)  | Out-Null
        $i.SubItems.Add($row.Address) | Out-Null
        $list.Items.Add($i) | Out-Null
    }
    $lblCount.Text = "Records: $($rows.Count)"
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
    $list.BackColor = '#111111'
    $list.ForeColor = 'Aquamarine'
    $txtSearch.BackColor = '#1e1e1e'
    $txtSearch.ForeColor = 'Aquamarine'
}

# ---------------- UI ----------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Actors Viewer — Light & Dark Mode"
$form.Size = '1450,800'
$form.StartPosition = 'CenterScreen'

# ---------- Top Panel ----------
$topPanel = New-Object System.Windows.Forms.Panel
$topPanel.Dock = 'Top'
$topPanel.Height = 80

$lblSearch = New-Object System.Windows.Forms.Label
$lblSearch.Text = "Live Search (Hero Name):"
$lblSearch.Location = '20,28'
$lblSearch.AutoSize = $true

$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Location = '240,25'
$txtSearch.Width = 400
$txtSearch.Font = New-Object System.Drawing.Font("Segoe UI",12)

$btnLight = New-Object System.Windows.Forms.Button
$btnLight.Text = "☀ Light Theme"
$btnLight.Location = '700,18'
$btnLight.Size = '160,45'
$btnLight.Font = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)

$btnDark = New-Object System.Windows.Forms.Button
$btnDark.Text = "🌙 Dark Theme"
$btnDark.Location = '880,18'
$btnDark.Size = '160,45'
$btnDark.Font = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)

$topPanel.Controls.AddRange(@(
    $lblSearch,$txtSearch,$btnLight,$btnDark
))
$form.Controls.Add($topPanel)

# ---------- ListView ----------
$list = New-Object System.Windows.Forms.ListView
$list.Dock = 'Fill'
$list.View = 'Details'
$list.FullRowSelect = $true
$list.GridLines = $true
$list.Font = New-Object System.Drawing.Font("Segoe UI",13)
$list.HideSelection = $false

$list.Columns.Add("Hero Name",350)      | Out-Null
$list.Columns.Add("Role",350)           | Out-Null
$list.Columns.Add("Series / Movie",450) | Out-Null
$list.Columns.Add("Address",300)        | Out-Null

$form.Controls.Add($list)

# ---------- Bottom Info ----------
$lblCount = New-Object System.Windows.Forms.Label
$lblCount.Dock = 'Bottom'
$lblCount.Height = 35
$lblCount.TextAlign = 'MiddleCenter'
$lblCount.Font = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
$form.Controls.Add($lblCount)

# ---------------- EVENTS ----------------
$form.Add_Shown({
    $global:AllRows = Get-ActorRows
    Load-List $AllRows
    Apply-DarkTheme
})

$txtSearch.Add_TextChanged({
    $filter = $txtSearch.Text.Trim()
    if ($filter) {
        Load-List (Get-ActorRows $filter)
    } else {
        Load-List $AllRows
    }
})

$btnLight.Add_Click({ Apply-LightTheme })
$btnDark.Add_Click({ Apply-DarkTheme })

# ---------------- RUN ----------------
[void]$form.ShowDialog()
