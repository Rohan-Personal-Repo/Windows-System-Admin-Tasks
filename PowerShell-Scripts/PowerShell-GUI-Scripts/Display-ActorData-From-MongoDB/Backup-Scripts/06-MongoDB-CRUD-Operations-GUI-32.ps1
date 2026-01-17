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
                actorName       = $d.heroName
                roleName        = $r.roleName
                seriesMovieName = $r.seriesMovieTitle
                roleAddress     = $r.Address
            }
        }
    }
    return $rows
}

# ---------- Fonts ----------
$fontHeader = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$fontRow    = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Italic)
$fontLabel  = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)

# ---------- Form ----------
$form               = New-Object System.Windows.Forms.Form
$form.Text          = "Actors Viewer (MongoDB + Mdbc)"
$form.Size          = New-Object System.Drawing.Size(1400, 800)   # larger
$form.MinimumSize   = New-Object System.Drawing.Size(1200, 700)
$form.StartPosition = 'CenterScreen'

# ---------- Top panel ----------
$topPanel           = New-Object System.Windows.Forms.Panel
$topPanel.Dock      = 'Top'
$topPanel.Height    = 80

$lblSearch          = New-Object System.Windows.Forms.Label
$lblSearch.Text     = "Live Search (Hero Name):"
$lblSearch.Location = New-Object System.Drawing.Point(20, 26)
$lblSearch.AutoSize = $true
$lblSearch.Font     = $fontLabel

$txtSearch          = New-Object System.Windows.Forms.TextBox
$txtSearch.Location = New-Object System.Drawing.Point(260, 24)
$txtSearch.Width    = 380
$txtSearch.Font     = $fontRow

$btnLight           = New-Object System.Windows.Forms.Button
$btnLight.Text      = "Light"
$btnLight.Location  = New-Object System.Drawing.Point(670, 20)
$btnLight.Size      = New-Object System.Drawing.Size(90, 34)
$btnLight.Font      = $fontLabel

$btnDark            = New-Object System.Windows.Forms.Button
$btnDark.Text       = "Dark"
$btnDark.Location   = New-Object System.Drawing.Point(770, 20)
$btnDark.Size       = New-Object System.Drawing.Size(90, 34)
$btnDark.Font       = $fontLabel

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
$list.OwnerDraw         = $false          # NO owner draw → no hover effects[web:197][web:198]
$list.HeaderStyle       = 'Clickable'     # standard clickable, always visible[web:199]

# Define headers (names you specified)
$null = $list.Columns.Add("actorName",       280)
$null = $list.Columns.Add("roleName",        260)
$null = $list.Columns.Add("seriesMovieName", 420)
$null = $list.Columns.Add("roleAddress",     280)

$form.Controls.Add($list)

# ---------- Footer ----------
$lblCount           = New-Object System.Windows.Forms.Label
$lblCount.Dock      = 'Bottom'
$lblCount.Height    = 30
$lblCount.TextAlign = 'MiddleCenter'
$lblCount.Font      = $fontLabel
$form.Controls.Add($lblCount)

# ---------- Theme helpers ----------
function Apply-LightTheme {
    $form.BackColor     = [System.Drawing.Color]::LemonChiffon
    $topPanel.BackColor = [System.Drawing.Color]::LemonChiffon
    $form.ForeColor     = [System.Drawing.Color]::Purple

    $lblSearch.ForeColor = [System.Drawing.Color]::Purple
    $lblCount.ForeColor  = [System.Drawing.Color]::Purple

    $txtSearch.BackColor = [System.Drawing.Color]::White
    $txtSearch.ForeColor = [System.Drawing.Color]::Purple

    $list.BackColor      = [System.Drawing.Color]::White
    $list.ForeColor      = [System.Drawing.Color]::Purple

    # headers bold + purple
    foreach ($col in $list.Columns) {
        $col.Font = $fontHeader   # respected by standard ListView for header
    }
}

function Apply-DarkTheme {
    $form.BackColor     = [System.Drawing.Color]::Black
    $topPanel.BackColor = [System.Drawing.Color]::Black
    $form.ForeColor     = [System.Drawing.Color]::Aquamarine

    $lblSearch.ForeColor = [System.Drawing.Color]::Aquamarine
    $lblCount.ForeColor  = [System.Drawing.Color]::Aquamarine

    $txtSearch.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
    $txtSearch.ForeColor = [System.Drawing.Color]::Aquamarine

    $list.BackColor      = [System.Drawing.Color]::FromArgb(17,17,17)
    $list.ForeColor      = [System.Drawing.Color]::Aquamarine

    foreach ($col in $list.Columns) {
        $col.Font = $fontHeader
    }
}

# ---------- Data loading ----------
function Load-List {
    param($rows)

    $list.BeginUpdate()
    $list.Items.Clear()

    foreach ($row in $rows) {
        $item = New-Object System.Windows.Forms.ListViewItem($row.actorName)
        $item.Font = $fontRow  # italic value

        $sub1 = $item.SubItems.Add($row.roleName)
        $sub1.Font = $fontRow

        $sub2 = $item.SubItems.Add($row.seriesMovieName)
        $sub2.Font = $fontRow

        $sub3 = $item.SubItems.Add($row.roleAddress)
        $sub3.Font = $fontRow

        [void]$list.Items.Add($item)
    }

    $list.AutoResizeColumns([System.Windows.Forms.ColumnHeaderAutoResizeStyle]::HeaderSize)
    $list.EndUpdate()

    $lblCount.Text = "Records: {0}" -f ($rows.Count)
}

# ---------- Events ----------
$form.Add_Shown({
    $global:AllRows = Get-ActorRows
    Load-List $AllRows
    Apply-LightTheme
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
