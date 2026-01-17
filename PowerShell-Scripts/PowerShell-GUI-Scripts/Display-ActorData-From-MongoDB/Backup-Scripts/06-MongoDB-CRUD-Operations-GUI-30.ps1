Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Import-Module Mdbc -ErrorAction Stop

# ---------- MongoDB ----------
Connect-Mdbc -ConnectionString $env:MONGO_CONN_STRING `
             -DatabaseName "ActorsDatabase" `
             -CollectionName "ActorsData"

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
            if (-not $r) { continue }
            $rows += [PSCustomObject]@{
                Hero    = $d.heroName
                Role    = $r.roleName
                Series  = $r.seriesMovieTitle
                Address = $r.Address
            }
        }
    }
    return $rows
}

function Load-List {
    param($rows)

    $list.BeginUpdate()
    $list.Items.Clear()

    foreach ($row in $rows) {
        $item = New-Object System.Windows.Forms.ListViewItem($row.Hero)
        [void]$item.SubItems.Add($row.Role)
        [void]$item.SubItems.Add($row.Series)
        [void]$item.SubItems.Add($row.Address)
        [void]$list.Items.Add($item)
    }

    $list.AutoResizeColumns([System.Windows.Forms.ColumnHeaderAutoResizeStyle]::HeaderSize)
    $list.EndUpdate()

    $lblCount.Text = "Records: {0}" -f ($rows.Count)
}

# ---------- Fonts ----------
$fontHeader = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$fontRow    = New-Object System.Drawing.Font("Segoe UI", 11)

# ---------- Form ----------
$form               = New-Object System.Windows.Forms.Form
$form.Text          = "Actors Viewer (MongoDB + Mdbc)"
$form.Size          = New-Object System.Drawing.Size(1280, 720)
$form.StartPosition = 'CenterScreen'

# ---------- Top panel ----------
$topPanel           = New-Object System.Windows.Forms.Panel
$topPanel.Dock      = 'Top'
$topPanel.Height    = 70

$lblSearch          = New-Object System.Windows.Forms.Label
$lblSearch.Text     = "Live Search (Hero Name):"
$lblSearch.Location = New-Object System.Drawing.Point(20, 24)
$lblSearch.AutoSize = $true
$lblSearch.Font     = $fontHeader

$txtSearch          = New-Object System.Windows.Forms.TextBox
$txtSearch.Location = New-Object System.Drawing.Point(260, 22)
$txtSearch.Width    = 350
$txtSearch.Font     = $fontRow

$btnLight           = New-Object System.Windows.Forms.Button
$btnLight.Text      = "Light"
$btnLight.Location  = New-Object System.Drawing.Point(640, 18)
$btnLight.Size      = New-Object System.Drawing.Size(90, 32)

$btnDark            = New-Object System.Windows.Forms.Button
$btnDark.Text       = "Dark"
$btnDark.Location   = New-Object System.Drawing.Point(740, 18)
$btnDark.Size       = New-Object System.Drawing.Size(90, 32)

$topPanel.Controls.AddRange(@($lblSearch,$txtSearch,$btnLight,$btnDark))
$form.Controls.Add($topPanel)

# ---------- ListView ----------
$list                   = New-Object System.Windows.Forms.ListView
$list.Dock              = 'Fill'
$list.View              = 'Details'
$list.FullRowSelect     = $true
$list.GridLines         = $true
$list.HideSelection     = $false
$list.Font              = $fontRow
$list.OwnerDraw         = $false   # IMPORTANT: standard drawing, no hover bugs

[void]$list.Columns.Add("Hero",          260)
[void]$list.Columns.Add("Role",          240)
[void]$list.Columns.Add("Series/Movie",  360)
[void]$list.Columns.Add("Address",       260)

$form.Controls.Add($list)

# ---------- Footer ----------
$lblCount           = New-Object System.Windows.Forms.Label
$lblCount.Dock      = 'Bottom'
$lblCount.Height    = 28
$lblCount.TextAlign = 'MiddleCenter'
$lblCount.Font      = $fontHeader
$form.Controls.Add($lblCount)

# ---------- Themes ----------
function Apply-LightTheme {
    $form.BackColor     = 'White'
    $topPanel.BackColor = 'White'
    $form.ForeColor     = 'Black'

    $lblSearch.ForeColor = 'Black'
    $lblCount.ForeColor  = 'Black'

    $txtSearch.BackColor = 'White'
    $txtSearch.ForeColor = 'Black'

    $list.BackColor      = 'White'
    $list.ForeColor      = 'Black'
}

function Apply-DarkTheme {
    $form.BackColor     = [System.Drawing.Color]::FromArgb(32,32,32)
    $topPanel.BackColor = [System.Drawing.Color]::FromArgb(32,32,32)
    $form.ForeColor     = 'White'

    $lblSearch.ForeColor = 'White'
    $lblCount.ForeColor  = 'White'

    $txtSearch.BackColor = [System.Drawing.Color]::FromArgb(48,48,48)
    $txtSearch.ForeColor = 'White'

    $list.BackColor      = [System.Drawing.Color]::FromArgb(24,24,24)
    $list.ForeColor      = 'White'
}

# ---------- Events ----------
$form.Add_Shown({
    $global:AllRows = Get-ActorRows
    Load-List $AllRows
    Apply-LightTheme       # default; click Dark to toggle
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

# ---------- Run ----------
[void]$form.ShowDialog()
