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
# Windows Forms UI
# -----------------------------

$form               = New-Object System.Windows.Forms.Form
$form.Text          = "Actors Database CRUD (MongoDB + Mdbc)"
$form.Size          = New-Object System.Drawing.Size(1000, 650)
$form.StartPosition = "CenterScreen"
$form.BackColor     = [System.Drawing.Color]::LemonChiffon
$form.Font          = New-Object System.Drawing.Font("Segoe UI", 10)
$form.ForeColor     = [System.Drawing.Color]::Purple

# Group box for inputs
$grpInput                  = New-Object System.Windows.Forms.GroupBox
$grpInput.Text             = "Hero / Role Details"
$grpInput.ForeColor        = [System.Drawing.Color]::Purple
$grpInput.BackColor        = [System.Drawing.Color]::Transparent
$grpInput.Location         = New-Object System.Drawing.Point(20, 20)
$grpInput.Size             = New-Object System.Drawing.Size(600, 170)

$lblHero              = New-Object System.Windows.Forms.Label
$lblHero.Text         = "Hero Name:"
$lblHero.Location     = New-Object System.Drawing.Point(20, 30)
$lblHero.AutoSize     = $true

$txtHero              = New-Object System.Windows.Forms.TextBox
$txtHero.Location     = New-Object System.Drawing.Point(150, 28)
$txtHero.Width        = 400

$lblRole              = New-Object System.Windows.Forms.Label
$lblRole.Text         = "Role Name:"
$lblRole.Location     = New-Object System.Drawing.Point(20, 65)
$lblRole.AutoSize     = $true

$txtRole              = New-Object System.Windows.Forms.TextBox
$txtRole.Location     = New-Object System.Drawing.Point(150, 63)
$txtRole.Width        = 400

$lblSeries            = New-Object System.Windows.Forms.Label
$lblSeries.Text       = "Series / Movie:"
$lblSeries.Location   = New-Object System.Drawing.Point(20, 100)
$lblSeries.AutoSize   = $true

$txtSeries            = New-Object System.Windows.Forms.TextBox
$txtSeries.Location   = New-Object System.Drawing.Point(150, 98)
$txtSeries.Width      = 400

$lblLocation          = New-Object System.Windows.Forms.Label
$lblLocation.Text     = "Location:"
$lblLocation.Location = New-Object System.Drawing.Point(20, 135)
$lblLocation.AutoSize = $true

$txtLocation          = New-Object System.Windows.Forms.TextBox
$txtLocation.Location = New-Object System.Drawing.Point(150, 133)
$txtLocation.Width    = 400

$grpInput.Controls.AddRange(@(
    $lblHero, $txtHero,
    $lblRole, $txtRole,
    $lblSeries, $txtSeries,
    $lblLocation, $txtLocation
))

# Group box for update/delete specifics
$grpExtra                  = New-Object System.Windows.Forms.GroupBox
$grpExtra.Text             = "Update / Delete Options"
$grpExtra.ForeColor        = [System.Drawing.Color]::Purple
$grpExtra.BackColor        = [System.Drawing.Color]::Transparent
$grpExtra.Location         = New-Object System.Drawing.Point(640, 20)
$grpExtra.Size             = New-Object System.Drawing.Size(330, 170)

$lblMatchRole          = New-Object System.Windows.Forms.Label
$lblMatchRole.Text     = "Match Role (rename):"
$lblMatchRole.Location = New-Object System.Drawing.Point(15, 35)
$lblMatchRole.AutoSize = $true

$txtMatchRole          = New-Object System.Windows.Forms.TextBox
$txtMatchRole.Location = New-Object System.Drawing.Point(15, 55)
$txtMatchRole.Width    = 290

$lblDeleteRole          = New-Object System.Windows.Forms.Label
$lblDeleteRole.Text     = "Role to Delete:"
$lblDeleteRole.Location = New-Object System.Drawing.Point(15, 95)
$lblDeleteRole.AutoSize = $true

$txtDeleteRole          = New-Object System.Windows.Forms.TextBox
$txtDeleteRole.Location = New-Object System.Drawing.Point(15, 115)
$txtDeleteRole.Width    = 290

$grpExtra.Controls.AddRange(@(
    $lblMatchRole, $txtMatchRole,
    $lblDeleteRole, $txtDeleteRole
))

# Buttons row
$btnCreateUpdate              = New-Object System.Windows.Forms.Button
$btnCreateUpdate.Text         = "Create / Append Role"
$btnCreateUpdate.Location     = New-Object System.Drawing.Point(20, 210)
$btnCreateUpdate.Size         = New-Object System.Drawing.Size(180, 35)
$btnCreateUpdate.BackColor    = [System.Drawing.Color]::White

$btnUpdateRoleName              = New-Object System.Windows.Forms.Button
$btnUpdateRoleName.Text         = "Update Role Name"
$btnUpdateRoleName.Location     = New-Object System.Drawing.Point(220, 210)
$btnUpdateRoleName.Size         = New-Object System.Drawing.Size(180, 35)
$btnUpdateRoleName.BackColor    = [System.Drawing.Color]::White

$btnDeleteRole              = New-Object System.Windows.Forms.Button
$btnDeleteRole.Text         = "Delete Role"
$btnDeleteRole.Location     = New-Object System.Drawing.Point(420, 210)
$btnDeleteRole.Size         = New-Object System.Drawing.Size(140, 35)
$btnDeleteRole.BackColor    = [System.Drawing.Color]::White

$btnReadOne              = New-Object System.Windows.Forms.Button
$btnReadOne.Text         = "Read One Hero"
$btnReadOne.Location     = New-Object System.Drawing.Point(580, 210)
$btnReadOne.Size         = New-Object System.Drawing.Size(160, 35)
$btnReadOne.BackColor    = [System.Drawing.Color]::White

$btnReadAll              = New-Object System.Windows.Forms.Button
$btnReadAll.Text         = "Read All Heroes"
$btnReadAll.Location     = New-Object System.Drawing.Point(760, 210)
$btnReadAll.Size         = New-Object System.Drawing.Size(160, 35)
$btnReadAll.BackColor    = [System.Drawing.Color]::White

# Status label
$lblStatus              = New-Object System.Windows.Forms.Label
$lblStatus.Text         = "Ready."
$lblStatus.Location     = New-Object System.Drawing.Point(20, 255)
$lblStatus.AutoSize     = $true
$lblStatus.ForeColor    = [System.Drawing.Color]::Purple

# DataGridView
$grid                   = New-Object System.Windows.Forms.DataGridView
$grid.Location          = New-Object System.Drawing.Point(20, 280)
$grid.Size              = New-Object System.Drawing.Size(950, 320)
$grid.ReadOnly          = $true
$grid.AllowUserToAddRows    = $false
$grid.AllowUserToDeleteRows = $false
$grid.AutoSizeColumnsMode   = "Fill"
$grid.BackgroundColor       = [System.Drawing.Color]::White

# -----------------------------
# Button event handlers
# -----------------------------

$btnCreateUpdate.Add_Click({
    $hero   = $txtHero.Text.Trim()
    $role   = $txtRole.Text.Trim()
    $series = $txtSeries.Text.Trim()
    $loc    = $txtLocation.Text.Trim()

    if (-not $hero -or -not $role -or -not $series -or -not $loc) {
        $lblStatus.Text = "Hero, Role, Series/Movie, and Location are all required."
        return
    }

    $msg = updateMultipleValues -heroName $hero `
                                -roleName $role `
                                -seriesMovieTitle $series `
                                -Address $loc

    $grid.DataSource = Get-FlattenedActors -heroNameFilter $hero
    $lblStatus.Text  = $msg
})

$btnUpdateRoleName.Add_Click({
    $hero       = $txtHero.Text.Trim()
    $newRole    = $txtRole.Text.Trim()
    $matchRole  = $txtMatchRole.Text.Trim()

    if (-not $hero -or -not $newRole) {
        $lblStatus.Text = "Hero and new Role Name are required for update."
        return
    }

    $msg = updateSingleValue -actorName $hero `
                             -newShowName $newRole `
                             -matchRoleName $matchRole

    $grid.DataSource = Get-FlattenedActors -heroNameFilter $hero
    $lblStatus.Text  = $msg
})

$btnDeleteRole.Add_Click({
    $roleToDelete = $txtDeleteRole.Text.Trim()

    if (-not $roleToDelete) {
        $lblStatus.Text = "Role name to delete is required."
        return
    }

    $msg = deleteActorByHero -roleName $roleToDelete

    $grid.DataSource = Get-FlattenedActors
    $lblStatus.Text  = $msg
})

$btnReadOne.Add_Click({
    $hero = $txtHero.Text.Trim()
    if (-not $hero) {
        $lblStatus.Text = "Hero name is required to read one."
        return
    }

    $rows = Get-FlattenedActors -heroNameFilter $hero
    if ($rows.Count -eq 0) {
        $lblStatus.Text = "No roles found for hero '$hero'."
    }
    else {
        $lblStatus.Text = "Loaded roles for hero '$hero'."
    }
    $grid.DataSource = $rows
})

$btnReadAll.Add_Click({
    $rows = Get-FlattenedActors
    $grid.DataSource = $rows
    $lblStatus.Text  = "Loaded all heroes and roles."
})

# -----------------------------
# Add controls to form
# -----------------------------
$form.Controls.AddRange(@(
    $grpInput,
    $grpExtra,
    $btnCreateUpdate, $btnUpdateRoleName, $btnDeleteRole, $btnReadOne, $btnReadAll,
    $lblStatus,
    $grid
))

# Show the form
[void]$form.ShowDialog()
