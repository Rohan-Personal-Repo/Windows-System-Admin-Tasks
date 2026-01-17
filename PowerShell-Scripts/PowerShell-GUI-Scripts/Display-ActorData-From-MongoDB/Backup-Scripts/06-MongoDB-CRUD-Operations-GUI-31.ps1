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
                actorName        = $d.heroName
                roleName         = $r.roleName
                seriesMovieName  = $r.seriesMovieTitle
                roleAddress      = $r.Address
            }
        }
    }
    return $rows
}

# ---------- Fonts ----------
$fontHeader = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$fontRow    = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Italic)

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
$list.OwnerDraw         = $true  # custom paint, but controlled

# headers with required captions
[void]$list.Columns.Add("actorName",        260)
[void]$list.Columns.Add("roleName",         240)
[void]$list.Columns.Add("seriesMovieName",  360)
[void]$list.Columns.Add("roleAddress",      260)

$form.Controls.Add($list)

# ---------- Footer ----------
$lblCount           = New-Object System.Windows.Forms.Label
$lblCount.Dock      = 'Bottom'
$lblCount.Height    = 28
$lblCount.TextAlign = 'MiddleCenter'
$lblCount.Font      = $fontHeader
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
}

# ---------- Draw headers ----------
$list.Add_DrawColumnHeader({
    param($sender,$e)

    $headerBack = [System.Drawing.Color]::FromArgb(64,64,64)
    $headerBrush = New-Object System.Drawing.SolidBrush($headerBack)
    $e.Graphics.FillRectangle($headerBrush, $e.Bounds)
    $headerBrush.Dispose()

    $rectF = New-Object System.Drawing.RectangleF(
        $e.Bounds.X, $e.Bounds.Y, $e.Bounds.Width, $e.Bounds.Height
    )

    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center

    $e.Graphics.DrawString(
        $e.Header.Text,
        $fontHeader,
        [System.Drawing.Brushes]::White,
        $rectF,
        $sf
    )

    $e.DrawDefault = $false
})

# ---------- Draw items (row background only) ----------
$list.Add_DrawItem({
    param($sender,$e)

    $isEven = ($e.ItemIndex % 2 -eq 0)
    $isDark = ($form.BackColor -eq [System.Drawing.Color]::Black)

    if ($isDark) {
        $rowBack = if ($isEven) {
            [System.Drawing.Color]::FromArgb(25,25,25)
        } else {
            [System.Drawing.Color]::FromArgb(35,35,35)
        }
    } else {
        $rowBack = if ($isEven) {
            [System.Drawing.Color]::White
        } else {
            [System.Drawing.Color]::FromArgb(245,245,245)
        }
    }

    if ($e.Item.Selected) {
        $rowBack = if ($isDark) {
            [System.Drawing.Color]::DarkSlateGray
        } else {
            [System.Drawing.Color]::LightBlue
        }
    }

    $brush = New-Object System.Drawing.SolidBrush($rowBack)
    $e.Graphics.FillRectangle($brush, $e.Bounds)
    $brush.Dispose()
    # SubItem drawing happens in DrawSubItem
    $e.DrawDefault = $false
})

# ---------- Draw subitems (text) ----------
$list.Add_DrawSubItem({
    param($sender,$e)

    $bounds = [System.Drawing.Rectangle]$e.Bounds
    $isDark = ($form.BackColor -eq [System.Drawing.Color]::Black)

    if ($e.Item.Selected) {
        $textBrush = [System.Drawing.Brushes]::White
    } else {
        $textBrush = if ($isDark) {
            [System.Drawing.Brushes]::Aquamarine
        } else {
            [System.Drawing.Brushes]::Purple
        }
    }

    $e.Graphics.DrawString(
        [string]$e.SubItem.Text,
        $fontRow,                       # italic values
        $textBrush,
        [float]($bounds.X + 5),
        [float]($bounds.Y + 3)
    )

    $e.DrawDefault = $false
})

# ---------- Load data ----------
function Load-List {
    param($rows)

    $list.BeginUpdate()
    $list.Items.Clear()

    foreach ($row in $rows) {
        $item = New-Object System.Windows.Forms.ListViewItem($row.actorName)
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
    Apply-LightTheme   # start with LemonChiffon + purple
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
