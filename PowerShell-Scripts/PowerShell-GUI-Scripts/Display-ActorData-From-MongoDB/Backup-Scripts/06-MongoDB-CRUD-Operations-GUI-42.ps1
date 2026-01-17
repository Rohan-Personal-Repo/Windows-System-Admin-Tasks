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
$form                   = New-Object System.Windows.Forms.Form
$form.Text              = "Actors Viewer (MongoDB + Mdbc)"
$form.Size              = New-Object System.Drawing.Size(1920, 1080)
$form.MinimumSize       = New-Object System.Drawing.Size(1800, 900)
$form.StartPosition     = 'CenterScreen'
$form.RightToLeft       = [System.Windows.Forms.RightToLeft]::No
$form.RightToLeftLayout = $false

# ---------- Top panel ----------
$topPanel              = New-Object System.Windows.Forms.Panel
$topPanel.Location     = New-Object System.Drawing.Point(0,0)
$topPanel.Size         = New-Object System.Drawing.Size(1904, 90)
$topPanel.Anchor       = "Top,Left,Right"

$lblSearch             = New-Object System.Windows.Forms.Label
$lblSearch.Text        = "Live Search (Hero Name):"
$lblSearch.Location    = New-Object System.Drawing.Point(20, 30)
$lblSearch.AutoSize    = $true
$lblSearch.Font        = $fontLabel

$txtSearch             = New-Object System.Windows.Forms.TextBox
$txtSearch.Location    = New-Object System.Drawing.Point(300, 26)
$txtSearch.Width       = 520
$txtSearch.Font        = $fontRow
$txtSearch.RightToLeft = [System.Windows.Forms.RightToLeft]::No
$txtSearch.TextAlign   = [System.Windows.Forms.HorizontalAlignment]::Left

# Light button
$btnLight              = New-Object System.Windows.Forms.Button
$btnLight.Text         = "Light"
$btnLight.Location     = New-Object System.Drawing.Point(1130, 20)
$btnLight.Size         = New-Object System.Drawing.Size(150, 50)
$btnLight.Font         = $fontLabel
$btnLight.BackColor    = [System.Drawing.Color]::LemonChiffon
$btnLight.ForeColor    = [System.Drawing.Color]::Purple

# Dark button
$btnDark               = New-Object System.Windows.Forms.Button
$btnDark.Text          = "Dark"
$btnDark.Location      = New-Object System.Drawing.Point(1290, 20)
$btnDark.Size          = New-Object System.Drawing.Size(150, 50)
$btnDark.Font          = $fontLabel
$btnDark.BackColor     = [System.Drawing.Color]::Black
$btnDark.ForeColor     = [System.Drawing.Color]::Aquamarine

$topPanel.Controls.AddRange(@($lblSearch,$txtSearch,$btnLight,$btnDark))
$form.Controls.Add($topPanel)

# ---------- ListView (no owner draw) ----------
$list               = New-Object System.Windows.Forms.ListView
$list.Location      = New-Object System.Drawing.Point(10, 90)
$list.Size          = New-Object System.Drawing.Size(1800, 900)
$list.Anchor        = "Top,Bottom,Left,Right"
$list.View          = 'Details'
$list.FullRowSelect = $true
$list.GridLines     = $true
$list.HotTracking   = $false
$list.HoverSelection= $false
$list.HideSelection = $false
$list.Font          = $fontRow
$list.OwnerDraw     = $false   # critical: use default drawing so items show [web:189][web:237]

$null = $list.Columns.Add("actorName",       320)
$null = $list.Columns.Add("roleName",        320)
$null = $list.Columns.Add("seriesMovieName", 520)
$null = $list.Columns.Add("roleAddress",     360)

$form.Controls.Add($list)

$list.Add_DrawColumnHeader({
    param($sender, $e)

    # detect current theme
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

    # fill header background
    $backBrush = New-Object System.Drawing.SolidBrush($backColor)
    $e.Graphics.FillRectangle($backBrush, $e.Bounds)
    $backBrush.Dispose()

    # center header text
    $rectF = New-Object System.Drawing.RectangleF(
        $e.Bounds.X, $e.Bounds.Y, $e.Bounds.Width, $e.Bounds.Height
    )

    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment     = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center

    $textBrush = New-Object System.Drawing.SolidBrush($textColor)
    $e.Graphics.DrawString(
        $e.Header.Text,
        $fontHeader,
        $textBrush,
        $rectF,
        $sf
    )
    $textBrush.Dispose()
    $sf.Dispose()

    $e.DrawDefault = $false
})

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

$txtSearch.Add_TextChanged({
    $filter = $txtSearch.Text.Trim()
    if ($filter) {
        Load-List (Get-ActorRows $filter)
    } else {
        Load-List $AllRows
    }
})

# ---------- Run ----------
[void]$form.ShowDialog()
