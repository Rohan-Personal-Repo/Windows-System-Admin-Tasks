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
    }
    else {
        $doc = [PSCustomObject]@{
            heroName = $heroName
            roles    = @($newRole)
        }
        Add-MdbcData -InputObject $doc
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
        heroName        = $actorName
        "roles.roleName" = $matchRoleName
    }

    $update = @{
        '$set' = @{
            "roles.$.roleName" = $newShowName
        }
    }

    Update-MdbcData -Filter $filter -Update $update
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

    $rows = @()

    foreach ($a in $actors) {
        if (-not $a.roles) { continue }

        $roles = if ($a.roles -is [System.Collections.IEnumerable] -and
                     -not ($a.roles -is [string])) {
                     $a.roles
                 } else {
                     @($a.roles)
                 }

        foreach ($r in $roles) {
            $rows += [PSCustomObject]@{
                HeroName         = $a.heroName
                RoleName         = $r.roleName
                SeriesMovieTitle = $r.seriesMovieTitle
                Address          = $r.Address
            }
        }
    }

    return $rows
}

# -----------------------------
# Windows Forms UI
# -----------------------------

# Form
$form                 = New-Object System.Windows.Forms.Form
$form.Text            = "Actors Database CRUD"
$form.Size            = New-Object System.Drawing.Size(900, 600)
$form.StartPosition   = "CenterScreen"
$form.BackColor       = [System.Drawing.Color]::LemonChiffon
$form.ForeColor       = [System.Drawing.Color]::Purple
$form.Font            = New-Object System.Drawing.Font("Segoe UI", 9)

# Labels & Textboxes
$lblHero              = New-Object System.Windows.Forms.Label
$lblHero.Text         = "Hero Name:"
$lblHero.Location     = New-Object System.Drawing.Point(20, 20)
$lblHero.AutoSize     = $true

$txtHero              = New-Object System.Windows.Forms.TextBox
$txtHero.Location     = New-Object System.Drawing.Point(150, 18)
$txtHero.Width        = 250

$lblRole              = New-Object System.Windows.Forms.Label
$lblRole.Text         = "Role Name:"
$lblRole.Location     = New-Object System.Drawing.Point(20, 50)
$lblRole.AutoSize     = $true

$txtRole              = New-Object System.Windows.Forms.TextBox
$txtRole.Location     = New-Object System.Drawing.Point(150, 48)
$txtRole.Width        = 250

$lblSeries            = New-Object System.Windows.Forms.Label
$lblSeries.Text       = "Series/Movie Title:"
$lblSeries.Location   = New-Object System.Drawing.Point(20, 80)
$lblSeries.AutoSize   = $true

$txtSeries            = New-Object System.Windows.Forms.TextBox
$txtSeries.Location   = New-Object System.Drawing.Point(150, 78)
$txtSeries.Width      = 250

$lblLocation          = New-Object System.Windows.Forms.Label
$lblLocation.Text     = "Location:"
$lblLocation.Location = New-Object System.Drawing.Point(20, 110)
$lblLocation.AutoSize = $true

$txtLocation          = New-Object System.Windows.Forms.TextBox
$txtLocation.Location = New-Object System.Drawing.Point(150, 108)
$txtLocation.Width    = 250

# Text boxes for "Update Role Name" and "Delete Role"
$lblMatchRole              = New-Object System.Windows.Forms.Label
$lblMatchRole.Text         = "Match Role (for rename):"
$lblMatchRole.Location     = New-Object System.Drawing.Point(20, 150)
$lblMatchRole.AutoSize     = $true

$txtMatchRole              = New-Object System.Windows.Forms.TextBox
$txtMatchRole.Location     = New-Object System.Drawing.Point(200, 148)
$txtMatchRole.Width        = 200

$lblDeleteRole             = New-Object System.Windows.Forms.Label
$lblDeleteRole.Text        = "Role to Delete:"
$lblDeleteRole.Location    = New-Object System.Drawing.Point(20, 180)
$lblDeleteRole.AutoSize    = $true

$txtDeleteRole             = New-Object System.Windows.Forms.TextBox
$txtDeleteRole.Location    = New-Object System.Drawing.Point(200, 178)
$txtDeleteRole.Width       = 200

# Buttons
$btnCreateUpdate      = New-Object System.Windows.Forms.Button
$btnCreateUpdate.Text = "Create / Append Role"
$btnCreateUpdate.Location = New-Object System.Drawing.Point(450, 18)
$btnCreateUpdate.Width = 180

$btnUpdateRoleName      = New-Object System.Windows.Forms.Button
$btnUpdateRoleName.Text = "Update Role Name"
$btnUpdateRoleName.Location = New-Object System.Drawing.Point(450, 58)
$btnUpdateRoleName.Width = 180

$btnDeleteRole      = New-Object System.Windows.Forms.Button
$btnDeleteRole.Text = "Delete Role"
$btnDeleteRole.Location = New-Object System.Drawing.Point(450, 98)
$btnDeleteRole.Width = 180

$btnReadOne      = New-Object System.Windows.Forms.Button
$btnReadOne.Text = "Read One Hero"
$btnReadOne.Location = New-Object System.Drawing.Point(650, 18)
$btnReadOne.Width = 180

$btnReadAll      = New-Object System.Windows.Forms.Button
$btnReadAll.Text = "Read All Heroes"
$btnReadAll.Location = New-Object System.Drawing.Point(650, 58)
$btnReadAll.Width = 180

# DataGridView to display results
$grid                   = New-Object System.Windows.Forms.DataGridView
$grid.Location          = New-Object System.Drawing.Point(20, 220)
$grid.Size              = New-Object System.Drawing.Size(840, 320)
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
        [System.Windows.Forms.MessageBox]::Show(
            "Hero, Role, Series/Movie, and Location are all required.",
            "Validation Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    updateMultipleValues -heroName $hero -roleName $role -seriesMovieTitle $series -Address $loc

    $grid.DataSource = Get-FlattenedActors -heroNameFilter $hero
})

$btnUpdateRoleName.Add_Click({
    $hero       = $txtHero.Text.Trim()
    $newRole    = $txtRole.Text.Trim()
    $matchRole  = $txtMatchRole.Text.Trim()

    if (-not $hero -or -not $newRole) {
        [System.Windows.Forms.MessageBox]::Show(
            "Hero and new Role Name are required.",
            "Validation Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    updateSingleValue -actorName $hero -newShowName $newRole -matchHeroName $matchRole

    $grid.DataSource = Get-FlattenedActors -heroNameFilter $hero
})

$btnDeleteRole.Add_Click({
    $roleToDelete = $txtDeleteRole.Text.Trim()

    if (-not $roleToDelete) {
        [System.Windows.Forms.MessageBox]::Show(
            "Role name to delete is required.",
            "Validation Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    deleteActorByHero -roleName $roleToDelete

    $grid.DataSource = Get-FlattenedActors
})

$btnReadOne.Add_Click({
    $hero = $txtHero.Text.Trim()
    if (-not $hero) {
        [System.Windows.Forms.MessageBox]::Show(
            "Hero name is required to read one.",
            "Validation Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    $grid.DataSource = Get-FlattenedActors -heroNameFilter $hero
})

$btnReadAll.Add_Click({
    $grid.DataSource = Get-FlattenedActors
})

# -----------------------------
# Add controls to form
# -----------------------------
$form.Controls.AddRange(@(
    $lblHero, $txtHero,
    $lblRole, $txtRole,
    $lblSeries, $txtSeries,
    $lblLocation, $txtLocation,
    $lblMatchRole, $txtMatchRole,
    $lblDeleteRole, $txtDeleteRole,
    $btnCreateUpdate, $btnUpdateRoleName, $btnDeleteRole,
    $btnReadOne, $btnReadAll,
    $grid
))

# Show the form
[void]$form.ShowDialog()