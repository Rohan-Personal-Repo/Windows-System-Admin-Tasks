# ---------------- UI ----------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Actors Viewer — Light & Dark Mode"
$form.Size = New-Object System.Drawing.Size(1280,720)
$form.StartPosition = 'CenterScreen'

# ---------- ListView ----------
$list = New-Object System.Windows.Forms.ListView
$list.Dock = 'Fill'
$list.View = 'Details'
$list.FullRowSelect = $true
$list.GridLines = $true
$list.HideSelection = $false

# Larger font for better readability
$fontRow = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Italic)
$list.Font = $fontRow

# Update columns with new header names and widths
$list.Columns.Clear()
$list.Columns.Add("actorName", 250)        | Out-Null
$list.Columns.Add("roleName", 250)         | Out-Null
$list.Columns.Add("seriesMovieTitle", 300) | Out-Null
$list.Columns.Add("roleAddress", 300)      | Out-Null

$form.Controls.Add($list)

# ---------- OwnerDraw Headers & SubItems ----------
$list.OwnerDraw = $true

# Draw headers
$list.Add_DrawColumnHeader({
    $_.Graphics.FillRectangle([System.Drawing.Brushes]::LightGray, $_.Bounds)
    $rectF = New-Object System.Drawing.RectangleF ($_.Bounds.X, $_.Bounds.Y, $_.Bounds.Width, $_.Bounds.Height)

    $stringFormat = New-Object System.Drawing.StringFormat
    $stringFormat.Alignment = [System.Drawing.StringAlignment]::Near
    $stringFormat.LineAlignment = [System.Drawing.StringAlignment]::Center

    $_.Graphics.DrawString(
        $_.Header.Text,
        $fontHeader,
        [System.Drawing.Brushes]::Black,
        $rectF,
        $stringFormat
    )
})

# Draw subitems
$list.Add_DrawItem({ })
$list.Add_DrawSubItem({
    $rectF = New-Object System.Drawing.RectangleF ($_.Bounds.X, $_.Bounds.Y, $_.Bounds.Width, $_.Bounds.Height)
    $stringFormat = New-Object System.Drawing.StringFormat
    $stringFormat.Alignment = [System.Drawing.StringAlignment]::Near
    $stringFormat.LineAlignment = [System.Drawing.StringAlignment]::Center

    $_.Graphics.DrawString(
        $_.SubItem.Text,
        $fontRow,
        [System.Drawing.Brushes]::White,
        $rectF,
        $stringFormat
    )
})
