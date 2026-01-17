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

function Load-List {
    param($rows)

    $list.Items.Clear()

    foreach ($row in $rows) {
        $item = New-Object System.Windows.Forms.ListViewItem($row.Hero)
        $item.SubItems.Add($row.Role)    | Out-Null
        $item.SubItems.Add($row.Series)  | Out-Null
        $item.SubItems.Add($row.Address) | Out-Null
        $list.Items.Add($item) | Out-Null
    }

    $lblCount.Text = "Records: $($rows.Count)"
    $list.AutoResizeColumns('HeaderSize')
}

# ---------------- THEMES ----------------
function Apply-LightTheme {
    $form.BackColor = 'LemonChiffon'
    $form.ForeColor = 'Purple'
    $topPanel.BackColor = 'LemonChiffon'

    $list.BackColor = 'White'
    $list.ForeColor = 'Purple'
    $list.Font = $fontRow

    $txtSearch.BackColor = 'White'
    $txtSearch.ForeColor = 'Purple'
}

function Apply-DarkTheme {
    $form.BackColor = 'Black'
    $form.ForeColor = 'Aquamarine'
    $topPanel.BackColor = 'Black'

    $list.BackColor = '#111111'
    $list.ForeColor = 'Aquamarine'
    $list.Font = $fontRow

    $txtSearch.BackColor = '#1e1e1e'
    $txtSearch.ForeColor = 'Aquamarine'
}

# ---------------- FONTS ----------------
$fontHeader = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$fontRow    = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Italic)
$fontBold   = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$fontButton = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)

# ---------------- UI ----------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Actors Viewer — Light & Dark Mode"
# $form.Size = New-Object System.Drawing.Size(1280,720)
$form.Size = New-Object System.Drawing.Size(1920,1080)
$form.StartPosition = 'CenterScreen'

# ---------- Top Panel ----------
$topPanel = New-Object System.Windows.Forms.Panel
$topPanel.Dock = 'Top'
$topPanel.Height = 90

$lblSearch = New-Object System.Windows.Forms.Label
$lblSearch.Text = "Live Search (Hero Name):"
$lblSearch.Location = '20,30'
$lblSearch.AutoSize = $true
$lblSearch.Font = $fontBold

$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Location = '270,26'
$txtSearch.Width = 420
$txtSearch.Font = $fontRow

$btnLight = New-Object System.Windows.Forms.Button
$btnLight.Text = "☀ LIGHT THEME"
$btnLight.Location = '720,18'
$btnLight.Size = '200,55'
$btnLight.Font = $fontButton

$btnDark = New-Object System.Windows.Forms.Button
$btnDark.Text = "🌙 DARK THEME"
$btnDark.Location = '940,18'
$btnDark.Size = '200,55'
$btnDark.Font = $fontButton

$topPanel.Controls.AddRange(@(
    $lblSearch,$txtSearch,$btnLight,$btnDark
))
$form.Controls.Add($topPanel)

# ---------------- FONTS ----------------
$fontHeader = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$fontRow    = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Regular)
$fontBold   = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$fontButton = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)

# ---------- ListView ----------
$list = New-Object System.Windows.Forms.ListView
$list.Dock = 'Fill'
$list.View = 'Details'
$list.FullRowSelect = $true
$list.GridLines = $true
$list.HideSelection = $false
$list.Font = $fontRow
$list.OwnerDraw = $true

# Columns with requested headers
$list.Columns.Add("actorName", 320)         | Out-Null
$list.Columns.Add("roleName", 300)         | Out-Null
$list.Columns.Add("Series/MovieTitle", 420)| Out-Null
$list.Columns.Add("roleAddress", 300)      | Out-Null

$form.Controls.Add($list)

# ---------- DrawItem (selection + alternating row colors) ----------
$list.Add_DrawItem({
    param($sender, $e)

    $isEven = $e.ItemIndex % 2 -eq 0

    # Alternating row color
    if ($form.BackColor -eq [System.Drawing.Color]::Black) {
        $rowBack = if ($isEven) { [System.Drawing.Color]::Black } else { [System.Drawing.Color]::FromArgb(30,30,30) }
    } else {
        $rowBack = if ($isEven) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::FromArgb(245,245,245) }
    }

    if ($e.Item.Selected) {
        $rowBack = if ($form.BackColor -eq [System.Drawing.Color]::Black) { [System.Drawing.Color]::DarkSlateGray } else { [System.Drawing.Color]::LightBlue }
    }

    $e.Graphics.FillRectangle((New-Object System.Drawing.SolidBrush $rowBack), $e.Bounds)
})

# ---------- DrawColumnHeader ----------
$list.Add_DrawColumnHeader({
    param($sender, $e)

    # Header background
    $headerBack = if ($form.BackColor -eq [System.Drawing.Color]::Black) { [System.Drawing.Color]::DimGray } else { [System.Drawing.Color]::LightGray }
    $e.Graphics.FillRectangle((New-Object System.Drawing.SolidBrush $headerBack), $e.Bounds)

    # Draw header text
    $rectF = New-Object System.Drawing.RectangleF ($e.Bounds.X, $e.Bounds.Y, $e.Bounds.Width, $e.Bounds.Height)
    $stringFormat = New-Object System.Drawing.StringFormat
    $stringFormat.Alignment = [System.Drawing.StringAlignment]::Center
    $stringFormat.LineAlignment = [System.Drawing.StringAlignment]::Center

    $e.Graphics.DrawString($e.Header.Text, $fontBold, [System.Drawing.Brushes]::Black, $rectF, $stringFormat)
})

# ---------- DrawSubItem ----------
$list.Add_DrawSubItem({
    param($sender, $e)

    # Ensure $e.Bounds is a single Rectangle
    $bounds = $e.Bounds
    if ($bounds -is [System.Array]) { $bounds = $bounds[0] }

    # Use a PointF for DrawString (top-left corner + small padding)
    $pointF = New-Object System.Drawing.PointF ($bounds.X + 5, $bounds.Y + 3)

    # Choose text color based on theme
    $textBrush = if ($form.BackColor -eq [System.Drawing.Color]::Black) {
        [System.Drawing.Brushes]::Aquamarine
    } else {
        [System.Drawing.Brushes]::Purple
    }

    # Highlight selected item text
    if ($e.Item.Selected) { $textBrush = [System.Drawing.SystemBrushes]::HighlightText }

    # Draw string using PointF (this works in PowerShell)
    $e.Graphics.DrawString([string]$e.SubItem.Text, $fontRow, $textBrush, $pointF)
})


# ---------- Footer ----------
$lblCount = New-Object System.Windows.Forms.Label
$lblCount.Dock = 'Bottom'
$lblCount.Height = 36
$lblCount.TextAlign = 'MiddleCenter'
$lblCount.Font = $fontBold
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
