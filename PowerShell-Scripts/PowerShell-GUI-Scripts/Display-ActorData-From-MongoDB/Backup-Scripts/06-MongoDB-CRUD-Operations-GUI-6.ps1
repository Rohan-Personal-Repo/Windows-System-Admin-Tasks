Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ... (same Mdbc setup and CRUD functions as before) ...

# -----------------------------
# Windows Forms UI (Tabbed, 1200x800)
# -----------------------------

$form               = New-Object System.Windows.Forms.Form
$form.Text          = "Actors Database CRUD (MongoDB + Mdbc)"
$form.Size          = New-Object System.Drawing.Size(1200, 900)
$form.MinimumSize   = New-Object System.Drawing.Size(1024, 768)
$form.StartPosition = "CenterScreen"
$form.BackColor     = [System.Drawing.Color]::LemonChiffon
$form.Font          = New-Object System.Drawing.Font("Segoe UI", 10)
$form.ForeColor     = [System.Drawing.Color]::Purple

# Tab control (top)
$tabs               = New-Object System.Windows.Forms.TabControl
$tabs.Location      = New-Object System.Drawing.Point(10, 10)
$tabs.Size          = New-Object System.Drawing.Size(1160, 320)
$tabs.Anchor        = "Top,Left,Right"

$tabCreate  = New-Object System.Windows.Forms.TabPage
$tabCreate.Text = "Create / Append Role"
$tabCreate.BackColor = [System.Drawing.Color]::LemonChiffon

$tabUpdate  = New-Object System.Windows.Forms.TabPage
$tabUpdate.Text = "Update Role Name"
$tabUpdate.BackColor = [System.Drawing.Color]::LemonChiffon

$tabDelete  = New-Object System.Windows.Forms.TabPage
$tabDelete.Text = "Delete Role"
$tabDelete.BackColor = [System.Drawing.Color]::LemonChiffon

$tabReadOne = New-Object System.Windows.Forms.TabPage
$tabReadOne.Text = "Read One Hero"
$tabReadOne.BackColor = [System.Drawing.Color]::LemonChiffon

$tabReadAll = New-Object System.Windows.Forms.TabPage
$tabReadAll.Text = "Read All Heroes"
$tabReadAll.BackColor = [System.Drawing.Color]::LemonChiffon

$tabs.TabPages.AddRange(@($tabCreate,$tabUpdate,$tabDelete,$tabReadOne,$tabReadAll))

# Grid (middle)
$grid                   = New-Object System.Windows.Forms.DataGridView
$grid.Location          = New-Object System.Drawing.Point(10, 340)
$grid.Size              = New-Object System.Drawing.Size(1160, 260)
$grid.ReadOnly          = $true
$grid.AllowUserToAddRows    = $false
$grid.AllowUserToDeleteRows = $false
$grid.AutoSizeColumnsMode   = "Fill"
$grid.BackgroundColor       = [System.Drawing.Color]::White
$grid.Anchor                = "Top,Left,Right"

# Big details textbox (bottom)
$txtDetails               = New-Object System.Windows.Forms.TextBox
$txtDetails.Location      = New-Object System.Drawing.Point(10, 610)
$txtDetails.Size          = New-Object System.Drawing.Size(1160, 200)
$txtDetails.Multiline     = $true
$txtDetails.ScrollBars    = "Vertical"
$txtDetails.Font          = New-Object System.Drawing.Font("Consolas", 10)
$txtDetails.BackColor     = [System.Drawing.Color]::White
$txtDetails.ForeColor     = [System.Drawing.Color]::Purple
$txtDetails.Anchor        = "Bottom,Left,Right"

# Status label
$lblStatus              = New-Object System.Windows.Forms.Label
$lblStatus.Text         = "Ready."
$lblStatus.Location     = New-Object System.Drawing.Point(10, 580)
$lblStatus.AutoSize     = $true
$lblStatus.ForeColor    = [System.Drawing.Color]::Purple
$lblStatus.Anchor       = "Left,Bottom"

# -----------------------------
# Controls per tab (same as last answer)
# -----------------------------
# ... create controls on $tabCreate, $tabUpdate, $tabDelete, $tabReadOne, $tabReadAll ...
# (use exactly the same controls and positions as in the previous script)

# For brevity, only showing one tab here; reuse previous definitions for all tabs:
$lblC_Hero          = New-Object System.Windows.Forms.Label
$lblC_Hero.Text     = "Hero Name:"
$lblC_Hero.Location = New-Object System.Drawing.Point(20, 30)
$lblC_Hero.AutoSize = $true

$txtC_Hero          = New-Object System.Windows.Forms.TextBox
$txtC_Hero.Location = New-Object System.Drawing.Point(150, 28)
$txtC_Hero.Width    = 400

# ... (rest of tabCreate / tabUpdate / tabDelete / tabReadOne / tabReadAll controls) ...

# -----------------------------
# Button handlers (as before) + details fill
# -----------------------------

# Helper to load full hero doc into details box
function Show-HeroDetailsInTextBox {
    param([string]$heroName)

    if (-not $heroName) {
        $txtDetails.Text = ""
        return
    }

    $doc = Get-MdbcData -Filter @{ heroName = $heroName } -First 1 -As PS
    if ($doc) {
        $txtDetails.Text = ($doc | ConvertTo-Json -Depth 5)
    }
    else {
        $txtDetails.Text = "No full document found for hero '$heroName'."
    }
}

$btnC_Submit.Add_Click({
    $hero   = $txtC_Hero.Text.Trim()
    $role   = $txtC_Role.Text.Trim()
    $series = $txtC_Series.Text.Trim()
    $loc    = $txtC_Location.Text.Trim()

    if (-not $hero -or -not $role -or -not $series -or -not $loc) {
        $lblStatus.Text = "Create/Append: Hero, Role, Series/Movie, and Location are required."
        return
    }

    $msg = updateMultipleValues -heroName $hero `
                                -roleName $role `
                                -seriesMovieTitle $series `
                                -Address $loc

    $grid.DataSource = Get-FlattenedActors -heroNameFilter $hero
    Show-HeroDetailsInTextBox -heroName $hero
    $lblStatus.Text  = $msg
})

$btnU_Submit.Add_Click({
    $hero      = $txtU_Hero.Text.Trim()
    $oldRole   = $txtU_MatchRole.Text.Trim()
    $newRole   = $txtU_NewRole.Text.Trim()

    if (-not $hero -or -not $newRole) {
        $lblStatus.Text = "Update: Hero and new Role Name are required."
        return
    }

    $msg = updateSingleValue -actorName $hero `
                             -newShowName $newRole `
                             -matchRoleName $oldRole

    $grid.DataSource = Get-FlattenedActors -heroNameFilter $hero
    Show-HeroDetailsInTextBox -heroName $hero
    $lblStatus.Text  = $msg
})

$btnD_Submit.Add_Click({
    $roleToDelete = $txtD_Role.Text.Trim()

    if (-not $roleToDelete) {
        $lblStatus.Text = "Delete: Role name to delete is required."
        return
    }

    $msg = deleteActorByHero -roleName $roleToDelete

    $grid.DataSource = Get-FlattenedActors
    $txtDetails.Text = ""
    $lblStatus.Text  = $msg
})

$btnR1_Submit.Add_Click({
    $hero = $txtR1_Hero.Text.Trim()

    if (-not $hero) {
        $lblStatus.Text = "Read One: Hero name is required."
        return
    }

    $rows = Get-FlattenedActors -heroNameFilter $hero
    $grid.DataSource = $rows
    Show-HeroDetailsInTextBox -heroName $hero

    if ($rows.Count -eq 0) {
        $lblStatus.Text = "Read One: No roles found for '$hero'."
    }
    else {
        $lblStatus.Text = "Read One: Loaded roles for '$hero'."
    }
})

$btnRA_Submit.Add_Click({
    $rows = Get-FlattenedActors
    $grid.DataSource = $rows
    $txtDetails.Text = ""
    $lblStatus.Text  = "Read All: Loaded all heroes and roles."
})

# Grid selection -> populate tabs and big textbox
$grid.Add_CellClick({
    param($sender, $e)

    if ($e.RowIndex -lt 0) { return } # ignore header

    $row = $grid.Rows[$e.RowIndex]

    $hero   = $row.Cells["HeroName"].Value
    $role   = $row.Cells["RoleName"].Value
    $series = $row.Cells["SeriesMovieTitle"].Value
    $loc    = $row.Cells["Address"].Value

    # Populate Create/Append tab
    $txtC_Hero.Text     = $hero
    $txtC_Role.Text     = $role
    $txtC_Series.Text   = $series
    $txtC_Location.Text = $loc

    # Populate Update tab
    $txtU_Hero.Text       = $hero
    $txtU_MatchRole.Text  = $role
    $txtU_NewRole.Text    = $role

    # Populate Delete tab
    $txtD_Role.Text = $role

    # Populate Read One tab
    $txtR1_Hero.Text = $hero

    # Show full hero document in big textbox
    Show-HeroDetailsInTextBox -heroName $hero

    $lblStatus.Text = "Selected '$hero' / '$role'. Details loaded into tabs and details box."
})

# -----------------------------
# Add main controls and show
# -----------------------------

$form.Controls.AddRange(@(
    $tabs,
    $grid,
    $lblStatus,
    $txtDetails
))

[void]$form.ShowDialog()
