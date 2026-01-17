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
$form.Size          = New-Object System.Drawing.Size(1920, 1080)
$form.MinimumSize   = New-Object System.Drawing.Size(1800, 900)
$form.StartPosition = 'CenterScreen'
$form.RightToLeft        = [System.Windows.Forms.RightToLeft]::No
$form.RightToLeftLayout  = $false

# ---------- Top panel (fixed height) ----------
$topPanel           = New-Object System.Windows.Forms.Panel
$topPanel.Location  = New-Object System.Drawing.Point(0,0)
$topPanel.Size      = New-Object System.Drawing.Size(1904, 90)
$topPanel.Anchor    = "Top,Left,Right"
$topPanel.RightToLeft = [System.Windows.Forms.RightToLeft]::No 

$lblSearch          = New-Object System.Windows.Forms.Label
$lblSearch.Text     = "Live Search (Hero Name):"
$lblSearch.Location = New-Object System.Drawing.Point(20, 30)
$lblSearch.AutoSize = $true
$lblSearch.Font     = $fontLabel

# bigger search box
$txtSearch          = New-Object System.Windows.Forms.TextBox
$txtSearch.Location = New-Object System.Drawing.Point(300, 26)
$txtSearch.Width    = 520    # change to a larger value, e.g. 800
$txtSearch.Font     = $fontRow
$txtSearch.Text = ""
$txtSearch.SelectionStart = 0
$txtSearch.SelectionLength = 0
$txtSearch.RightToLeft   = [System.Windows.Forms.RightToLeft]::No
$txtSearch.TextAlign     = [System.Windows.Forms.HorizontalAlignment]::Left

# Light button – LemonChiffon BG, purple text, bold
$btnLight           = New-Object System.Windows.Forms.Button
$btnLight.Text      = "Light"
$btnLight.Location  = New-Object System.Drawing.Point(1130, 20)
$btnLight.Size      = New-Object System.Drawing.Size(150, 50)
$btnLight.Font      = $fontLabel
$btnLight.BackColor = [System.Drawing.Color]::LemonChiffon
$btnLight.ForeColor = [System.Drawing.Color]::Purple
$btnLight.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard

# Dark button – Black BG, aquamarine text, bold
$btnDark            = New-Object System.Windows.Forms.Button
$btnDark.Text       = "Dark"
$btnDark.Location   = New-Object System.Drawing.Point(1290, 20)
$btnDark.Size       = New-Object System.Drawing.Size(150, 50)
$btnDark.Font       = $fontLabel
$btnDark.BackColor  = [System.Drawing.Color]::Black
$btnDark.ForeColor  = [System.Drawing.Color]::Aquamarine
$btnDark.FlatStyle  = [System.Windows.Forms.FlatStyle]::Standard

$topPanel.Controls.AddRange(@($lblSearch,$txtSearch,$btnLight,$btnDark))
$form.Controls.Add($topPanel)

# ---------- ListView (explicit margins, BELOW panel) ----------
$list                   = New-Object System.Windows.Forms.ListView
$list.Location          = New-Object System.Drawing.Point(10, 90)
$list.Size              = New-Object System.Drawing.Size(1800, 900)
$list.Anchor            = "Top,Bottom,Left,Right"
$list.View              = 'Details'
$list.FullRowSelect     = $true
$list.GridLines         = $true
$list.HideSelection     = $false
$list.Font              = $fontRow
$list.OwnerDraw         = $true   # enable custom header drawing only

# headers you want
$null = $list.Columns.Add("actorName",       280)
$null = $list.Columns.Add("roleName",        260)
$null = $list.Columns.Add("seriesMovieName", 420)
$null = $list.Columns.Add("roleAddress",     280)

$form.Controls.Add($list)

$list.Add_DrawColumnHeader({
    param($sender, $e)

    # Detect current theme by form.BackColor
    $isDark = ($form.BackColor -eq [System.Drawing.Color]::Black)

    $backColor = if ($isDark) {
        [System.Drawing.Color]::Black
    } else {
        [System.Drawing.Color]::LemonChiffon
    }

    $textColor = if ($isDark) {
        [System.Drawing.Color]::Aquamarine
    } else {
        [System.Drawing.Color]::Purple
    }

    $backBrush = New-Object System.Drawing.SolidBrush($backColor)
    $e.Graphics.FillRectangle($backBrush, $e.Bounds)
    $backBrush.Dispose()

    $rectF = New-Object System.Drawing.RectangleF(
        $e.Bounds.X, $e.Bounds.Y, $e.Bounds.Width, $e.Bounds.Height
    )

    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment     = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center

    $textBrush = New-Object System.Drawing.SolidBrush($textColor)
    $e.Graphics.DrawString(
        $e.Header.Text,
        $fontHeader,          # bold header font
        $textBrush,
        $rectF,
        $sf
    )
    $textBrush.Dispose()

    $e.DrawDefault = $false
})

$list.Add_DrawItem({ param($s,$e) $e.DrawDefault = $true })
$list.Add_DrawSubItem({ param($s,$e) $e.DrawDefault = $true })

# ---------- Footer ----------
$lblCount           = New-Object System.Windows.Forms.Label
$lblCount.Location  = New-Object System.Drawing.Point(0, 820)
$lblCount.Size      = New-Object System.Drawing.Size(1384, 30)
$lblCount.Anchor    = "Bottom,Left,Right"
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

    $list.BackColor      = [System.Drawing.Color]::LemonChiffon
    $list.ForeColor      = [System.Drawing.Color]::Purple

    # force header + rows to repaint for new theme
    $list.OwnerDraw = $true
    $list.Refresh()
    $list.Invalidate()
    $list.Update()
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

    # force header + rows to repaint for new theme
    $list.OwnerDraw = $true
    $list.Refresh()
    $list.Invalidate()
    $list.Update()
}


# ---------- Data loading ----------
function Load-List {
    param($rows)

    $list.BeginUpdate()
    $list.Items.Clear()

    foreach ($row in $rows) {
        $item = New-Object System.Windows.Forms.ListViewItem($row.actorName)
        $item.Font = $fontRow
        [void]$item.SubItems.Add($row.roleName)
        [void]$item.SubItems.Add($row.seriesMovieName)
        [void]$item.SubItems.Add($row.roleAddress)
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


$btnLight.Add_Click({ Apply-LightTheme })
$btnDark.Add_Click({ Apply-DarkTheme })

# To be very explicit, add a Shown handler on the form so the textbox always starts showing from the left:
$form.Add_Shown({
    $txtSearch.SelectionStart = 0
    $txtSearch.SelectionLength = 0
})

# Optional: Prevent auto‑scrolling while typing

$txtSearch.Add_TextChanged({
    # keep view from jumping so you always see from left
    $txtSearch.SelectionStart  = 0
    $txtSearch.SelectionLength = 0

    $filter = $txtSearch.Text.Trim()
    if ($filter) {
        Load-List (Get-ActorRows $filter)
    } else {
        Load-List $AllRows
    }
})
# ---------- Run ----------
[void]$form.ShowDialog()
