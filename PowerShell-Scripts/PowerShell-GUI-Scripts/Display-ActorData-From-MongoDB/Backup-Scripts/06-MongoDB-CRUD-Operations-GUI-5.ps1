Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# -----------------------------
# MongoDB / Mdbc setup
# -----------------------------
Import-Module Mdbc -ErrorAction Stop

$mongoServer    = $env:MONGO_CONN_STRING
$mongoDatabase  = "ActorsDatabase"
$collectionName = "ActorsData"

if (-not $mongoServer) {
    [System.Windows.Forms.MessageBox]::Show(
        "MONGO_CONN_STRING is not set. Set it before running.",
        "MongoDB Connection Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    return
}

Connect-Mdbc -ConnectionString $mongoServer `
             -DatabaseName $mongoDatabase `
             -CollectionName $collectionName

# -----------------------------
# CRUD helper functions
# -----------------------------

function New-Role {
    param(
        [string]$roleName,
        [string]$seriesMovieTitle,
        [string]$Address
    )
    [PSCustomObject]@{
        roleName         = $roleName
        seriesMovieTitle = $seriesMovieTitle
        Address          = $Address
    }
}

function updateMultipleValues {
    param(
        [Parameter(Mandatory)][string]$heroName,
        [Parameter(Mandatory)][string]$roleName,
        [Parameter(Mandatory)][string]$seriesMovieTitle,
        [Parameter(Mandatory)][string]$Address
    )

    $newRole = New-Role -roleName $roleName `
                        -seriesMovieTitle $seriesMovieTitle `
                        -Address $Address

    $existing = Get-MdbcData -Filter @{ heroName = $heroName } -First 1 -As PS

    if ($existing) {
        Update-MdbcData -Filter @{ _id = $existing._id } `
                        -Update @{ '$push' = @{ roles = $newRole } }
        return "Appended role to existing hero '$heroName'."
    }
    else {
        $doc = [PSCustomObject]@{
            heroName = $heroName
            roles    = @($newRole)
        }
        Add-MdbcData -InputObject $doc
        return "Created new hero '$heroName' with first role."
    }
}

function updateSingleValue {
    param(
        [Parameter(Mandatory)][string]$actorName,
        [Parameter(Mandatory)][string]$newShowName,
        [string]$matchRoleName = $null
    )

    if (-not $matchRoleName) { $matchRoleName = $newShowName }

    $filter = @{
        heroName         = $actorName
        "roles.roleName" = $matchRoleName
    }

    $update = @{
        '$set' = @{
            "roles.$.roleName" = $newShowName
        }
    }

    Update-MdbcData -Filter $filter -Update $update
    return "Updated role name for hero '$actorName'."
}

function deleteActorByHero {
    param(
        [Parameter(Mandatory)][string]$roleName
    )

    $filter = @{ "roles.roleName" = $roleName }

    $update = @{
        '$pull' = @{ roles = @{ roleName = $roleName } }
    }

    Update-MdbcData -Filter $filter -Update $update -Many
    return "Deleted role '$roleName' from all heroes."
}

function Get-FlattenedActors {
    param(
        [string]$heroNameFilter
    )

    if ($heroNameFilter) {
        $actors = Get-MdbcData -Filter @{ heroName = $heroNameFilter } -As PS
    }
    else {
        $actors = Get-MdbcData -As PS
    }

    $rows = New-Object System.Collections.Generic.List[object]

    foreach ($a in $actors) {
        if (-not $a.roles) { continue }

        $roles = if ($a.roles -is [System.Collections.IEnumerable] -and
                     -not ($a.roles -is [string])) {
                     $a.roles
                 } else {
                     @($a.roles)
                 }

        foreach ($r in $roles) {
            $row = [PSCustomObject]@{
                HeroName         = $a.heroName
                RoleName         = $r.roleName
                SeriesMovieTitle = $r.seriesMovieTitle
                Address          = $r.Address
            }
            $rows.Add($row)
        }
    }

    return $rows
}

# -----------------------------
# Windows Forms UI (Tabbed, 1200x800)
# -----------------------------

$form               = New-Object System.Windows.Forms.Form
$form.Text          = "Actors Database CRUD (MongoDB + Mdbc)"
$form.Size          = New-Object System.Drawing.Size(1200, 800)
$form.MinimumSize   = New-Object System.Drawing.Size(1024, 768)
$form.StartPosition = "CenterScreen"
$form.BackColor     = [System.Drawing.Color]::LemonChiffon
$form.Font          = New-Object System.Drawing.Font("Segoe UI", 10)
$form.ForeColor     = [System.Drawing.Color]::Purple

# Tab control
$tabs               = New-Object System.Windows.Forms.TabControl
$tabs.Location      = New-Object System.Drawing.Point(10, 10)
$tabs.Size          = New-Object System.Drawing.Size(1160, 320)
$tabs.Anchor        = "Top,Left,Right"

$tabCreate          = New-Object System.Windows.Forms.TabPage
$tabCreate.Text     = "Create / Append Role"
$tabCreate.BackColor = [System.Drawing.Color]::LemonChiffon

$tabUpdate          = New-Object System.Windows.Forms.TabPage
$tabUpdate.Text     = "Update Role Name"
$tabUpdate.BackColor = [System.Drawing.Color]::LemonChiffon

$tabDelete          = New-Object System.Windows.Forms.TabPage
$tabDelete.Text     = "Delete Role"
$tabDelete.BackColor = [System.Drawing.Color]::LemonChiffon

$tabReadOne         = New-Object System.Windows.Forms.TabPage
$tabReadOne.Text    = "Read One Hero"
$tabReadOne.BackColor = [System.Drawing.Color]::LemonChiffon

$tabReadAll         = New-Object System.Windows.Forms.TabPage
$tabReadAll.Text    = "Read All Heroes"
$tabReadAll.BackColor = [System.Drawing.Color]::LemonChiffon

$tabs.TabPages.AddRange(@(
    $tabCreate, $tabUpdate, $tabDelete, $tabReadOne, $tabReadAll
))

# Shared grid
$grid                   = New-Object System.Windows.Forms.DataGridView
$grid.Location          = New-Object System.Drawing.Point(10, 340)
$grid.Size              = New-Object System.Drawing.Size(1160, 360)
$grid.ReadOnly          = $true
$grid.AllowUserToAddRows    = $false
$grid.AllowUserToDeleteRows = $false
$grid.AutoSizeColumnsMode   = "Fill"
$grid.BackgroundColor       = [System.Drawing.Color]::White
$grid.Anchor                = "Top,Bottom,Left,Right"

# Status label
$lblStatus              = New-Object System.Windows.Forms.Label
$lblStatus.Text         = "Ready."
$lblStatus.Location     = New-Object System.Drawing.Point(10, 710)
$lblStatus.AutoSize     = $true
$lblStatus.ForeColor    = [System.Drawing.Color]::Purple
$lblStatus.Anchor       = "Left,Bottom"

# -----------------------------
# Controls per tab
# -----------------------------

# --- Tab: Create / Append ---
$lblC_Hero          = New-Object System.Windows.Forms.Label
$lblC_Hero.Text     = "Hero Name:"
$lblC_Hero.Location = New-Object System.Drawing.Point(20, 30)
$lblC_Hero.AutoSize = $true

$txtC_Hero          = New-Object System.Windows.Forms.TextBox
$txtC_Hero.Location = New-Object System.Drawing.Point(150, 28)
$txtC_Hero.Width    = 400

$lblC_Role          = New-Object System.Windows.Forms.Label
$lblC_Role.Text     = "Role Name:"
$lblC_Role.Location = New-Object System.Drawing.Point(20, 70)
$lblC_Role.AutoSize = $true

$txtC_Role          = New-Object System.Windows.Forms.TextBox
$txtC_Role.Location = New-Object System.Drawing.Point(150, 68)
$txtC_Role.Width    = 400

$lblC_Series        = New-Object System.Windows.Forms.Label
$lblC_Series.Text   = "Series / Movie:"
$lblC_Series.Location = New-Object System.Drawing.Point(20, 110)
$lblC_Series.AutoSize = $true

$txtC_Series        = New-Object System.Windows.Forms.TextBox
$txtC_Series.Location = New-Object System.Drawing.Point(150, 108)
$txtC_Series.Width  = 400

$lblC_Location        = New-Object System.Windows.Forms.Label
$lblC_Location.Text   = "Location:"
$lblC_Location.Location = New-Object System.Drawing.Point(20, 150)
$lblC_Location.AutoSize = $true

$txtC_Location        = New-Object System.Windows.Forms.TextBox
$txtC_Location.Location = New-Object System.Drawing.Point(150, 148)
$txtC_Location.Width  = 400

$btnC_Submit          = New-Object System.Windows.Forms.Button
$btnC_Submit.Text     = "Create / Append Role"
$btnC_Submit.Location = New-Object System.Drawing.Point(600, 80)
$btnC_Submit.Size     = New-Object System.Drawing.Size(220, 40)
$btnC_Submit.BackColor= [System.Drawing.Color]::White

$tabCreate.Controls.AddRange(@(
    $lblC_Hero, $txtC_Hero,
    $lblC_Role, $txtC_Role,
    $lblC_Series, $txtC_Series,
    $lblC_Location, $txtC_Location,
    $btnC_Submit
))

# --- Tab: Update Role Name ---
$lblU_Hero          = New-Object System.Windows.Forms.Label
$lblU_Hero.Text     = "Hero Name:"
$lblU_Hero.Location = New-Object System.Drawing.Point(20, 40)
$lblU_Hero.AutoSize = $true

$txtU_Hero          = New-Object System.Windows.Forms.TextBox
$txtU_Hero.Location = New-Object System.Drawing.Point(150, 38)
$txtU_Hero.Width    = 400

$lblU_MatchRole          = New-Object System.Windows.Forms.Label
$lblU_MatchRole.Text     = "Existing Role Name to Match:"
$lblU_MatchRole.Location = New-Object System.Drawing.Point(20, 80)
$lblU_MatchRole.AutoSize = $true

$txtU_MatchRole          = New-Object System.Windows.Forms.TextBox
$txtU_MatchRole.Location = New-Object System.Drawing.Point(250, 78)
$txtU_MatchRole.Width    = 300

$lblU_NewRole          = New-Object System.Windows.Forms.Label
$lblU_NewRole.Text     = "New Role Name:"
$lblU_NewRole.Location = New-Object System.Drawing.Point(20, 120)
$lblU_NewRole.AutoSize = $true

$txtU_NewRole          = New-Object System.Windows.Forms.TextBox
$txtU_NewRole.Location = New-Object System.Drawing.Point(150, 118)
$txtU_NewRole.Width    = 400

$btnU_Submit          = New-Object System.Windows.Forms.Button
$btnU_Submit.Text     = "Update Role Name"
$btnU_Submit.Location = New-Object System.Drawing.Point(600, 80)
$btnU_Submit.Size     = New-Object System.Drawing.Size(220, 40)
$btnU_Submit.BackColor= [System.Drawing.Color]::White

$tabUpdate.Controls.AddRange(@(
    $lblU_Hero, $txtU_Hero,
    $lblU_MatchRole, $txtU_MatchRole,
    $lblU_NewRole, $txtU_NewRole,
    $btnU_Submit
))

# --- Tab: Delete Role ---
$lblD_Role          = New-Object System.Windows.Forms.Label
$lblD_Role.Text     = "Role Name to Delete:"
$lblD_Role.Location = New-Object System.Drawing.Point(20, 60)
$lblD_Role.AutoSize = $true

$txtD_Role          = New-Object System.Windows.Forms.TextBox
$txtD_Role.Location = New-Object System.Drawing.Point(220, 58)
$txtD_Role.Width    = 400

$btnD_Submit          = New-Object System.Windows.Forms.Button
$btnD_Submit.Text     = "Delete Role"
$btnD_Submit.Location = New-Object System.Drawing.Point(650, 55)
$btnD_Submit.Size     = New-Object System.Drawing.Size(180, 40)
$btnD_Submit.BackColor= [System.Drawing.Color]::White

$tabDelete.Controls.AddRange(@(
    $lblD_Role, $txtD_Role,
    $btnD_Submit
))

# --- Tab: Read One Hero ---
$lblR1_Hero          = New-Object System.Windows.Forms.Label
$lblR1_Hero.Text     = "Hero Name:"
$lblR1_Hero.Location = New-Object System.Drawing.Point(20, 60)
$lblR1_Hero.AutoSize = $true

$txtR1_Hero          = New-Object System.Windows.Forms.TextBox
$txtR1_Hero.Location = New-Object System.Drawing.Point(150, 58)
$txtR1_Hero.Width    = 400

$btnR1_Submit          = New-Object System.Windows.Forms.Button
$btnR1_Submit.Text     = "Load Hero Roles"
$btnR1_Submit.Location = New-Object System.Drawing.Point(600, 55)
$btnR1_Submit.Size     = New-Object System.Drawing.Size(220, 40)
$btnR1_Submit.BackColor= [System.Drawing.Color]::White

$tabReadOne.Controls.AddRange(@(
    $lblR1_Hero, $txtR1_Hero,
    $btnR1_Submit
))

# --- Tab: Read All ---
$lblRA_Info          = New-Object System.Windows.Forms.Label
$lblRA_Info.Text     = "Click 'Load All' to display all heroes and roles."
$lblRA_Info.Location = New-Object System.Drawing.Point(20, 60)
$lblRA_Info.AutoSize = $true

$btnRA_Submit          = New-Object System.Windows.Forms.Button
$btnRA_Submit.Text     = "Load All"
$btnRA_Submit.Location = New-Object System.Drawing.Point(20, 100)
$btnRA_Submit.Size     = New-Object System.Drawing.Size(180, 40)
$btnRA_Submit.BackColor= [System.Drawing.Color]::White

$tabReadAll.Controls.AddRange(@(
    $lblRA_Info, $btnRA_Submit
))

# -----------------------------
# Button event handlers
# -----------------------------

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
    $lblStatus.Text  = "Read All: Loaded all heroes and roles."
})

# -----------------------------
# Grid selection -> populate details
# -----------------------------

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

    $lblStatus.Text = "Selected '$hero' / '$role' from grid. Details loaded into tabs."
})

# -----------------------------
# Add main controls and show
# -----------------------------

$form.Controls.AddRange(@(
    $tabs,
    $grid,
    $lblStatus
))

[void]$form.ShowDialog()
