Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Import-Module Mdbc -ErrorAction Stop

# ---------- MongoDB connection ----------
$mongoServer    = $env:MONGO_CONN_STRING
$mongoDatabase  = "ActorsDatabase"
$collectionName = "ActorsData"

if (-not $mongoServer) {
    [System.Windows.Forms.MessageBox]::Show("MONGO_CONN_STRING not set.","Error") | Out-Null
    return
}

Connect-Mdbc -ConnectionString $mongoServer `
             -DatabaseName $mongoDatabase `
             -CollectionName $collectionName

# ---------- Data helpers ----------
function Get-FlattenedActors {
    param([string]$heroNameFilter)

    if ($heroNameFilter) {
        $actors = Get-MdbcData -Filter @{ heroName = $heroNameFilter } -As PS
    } else {
        $actors = Get-MdbcData -As PS
    }

    $rows = New-Object System.Collections.Generic.List[object]

    foreach ($a in $actors) {
        if (-not $a.roles) { continue }

        $roles = if ($a.roles -is [System.Collections.IEnumerable] -and
                     -not ($a.roles -is [string])) { $a.roles } else { @($a.roles) }

        foreach ($r in $roles) {
            $rows.Add([PSCustomObject]@{
                HeroName         = $a.heroName
                RoleName         = $r.roleName
                SeriesMovieTitle = $r.seriesMovieTitle
                Address          = $r.Address
            })
        }
    }

    return $rows
}

function Show-RowOnLabels {
    param($rows, [int]$index, $lblHero, $lblRole, $lblSeries, $lblAddress, $lblInfo)

    if (-not $rows -or $rows.Count -eq 0) {
        $lblHero.Text    = "Hero: (none)"
        $lblRole.Text    = "Role: (none)"
        $lblSeries.Text  = "Series/Movie: (none)"
        $lblAddress.Text = "Address: (none)"
        $lblInfo.Text    = "0 of 0"
        return
    }

    if ($index -lt 0) { $index = 0 }
    if ($index -ge $rows.Count) { $index = $rows.Count - 1 }

    $row = $rows[$index]

    $lblHero.Text    = "Hero: "   + [string]$row.HeroName
    $lblRole.Text    = "Role: "   + [string]$row.RoleName
    $lblSeries.Text  = "Series/Movie: " + [string]$row.SeriesMovieTitle
    $lblAddress.Text = "Address: "      + [string]$row.Address
    $lblInfo.Text    = "Record {0} of {1}" -f ($index + 1), $rows.Count

    return $index
}

# ---------- UI ----------
$form               = New-Object System.Windows.Forms.Form
$form.Text          = "Actors Viewer (MongoDB + Mdbc)"
$form.Size          = New-Object System.Drawing.Size(1000, 600)
$form.MinimumSize   = New-Object System.Drawing.Size(900, 500)
$form.StartPosition = "CenterScreen"
$form.BackColor     = [System.Drawing.Color]::LemonChiffon
$form.Font          = New-Object System.Drawing.Font("Segoe UI", 11)
$form.ForeColor     = [System.Drawing.Color]::Purple

$tabs               = New-Object System.Windows.Forms.TabControl
$tabs.Location      = New-Object System.Drawing.Point(10, 10)
$tabs.Size          = New-Object System.Drawing.Size(960, 540)
$tabs.Anchor        = "Top,Bottom,Left,Right"

# ---------------- Tab 1: All Actors ----------------
$tabAll             = New-Object System.Windows.Forms.TabPage
$tabAll.Text        = "All Actors"
$tabAll.BackColor   = [System.Drawing.Color]::LemonChiffon

$lblAllHero         = New-Object System.Windows.Forms.Label
$lblAllHero.Location= New-Object System.Drawing.Point(20, 40)
$lblAllHero.AutoSize= $true

$lblAllRole         = New-Object System.Windows.Forms.Label
$lblAllRole.Location= New-Object System.Drawing.Point(20, 80)
$lblAllRole.AutoSize= $true

$lblAllSeries       = New-Object System.Windows.Forms.Label
$lblAllSeries.Location = New-Object System.Drawing.Point(20, 120)
$lblAllSeries.AutoSize = $true

$lblAllAddress      = New-Object System.Windows.Forms.Label
$lblAllAddress.Location = New-Object System.Drawing.Point(20, 160)
$lblAllAddress.AutoSize = $true

$lblAllInfo         = New-Object System.Windows.Forms.Label
$lblAllInfo.Location= New-Object System.Drawing.Point(20, 200)
$lblAllInfo.AutoSize= $true

$btnAllPrev         = New-Object System.Windows.Forms.Button
$btnAllPrev.Text    = "< Previous"
$btnAllPrev.Location= New-Object System.Drawing.Point(20, 240)
$btnAllPrev.Size    = New-Object System.Drawing.Size(100, 35)

$btnAllNext         = New-Object System.Windows.Forms.Button
$btnAllNext.Text    = "Next >"
$btnAllNext.Location= New-Object System.Drawing.Point(140, 240)
$btnAllNext.Size    = New-Object System.Drawing.Size(100, 35)

$tabAll.Controls.AddRange(@(
    $lblAllHero,$lblAllRole,$lblAllSeries,$lblAllAddress,$lblAllInfo,
    $btnAllPrev,$btnAllNext
))

# ---------------- Tab 2: Search by heroName ----------------
$tabSearch           = New-Object System.Windows.Forms.TabPage
$tabSearch.Text      = "Search by heroName"
$tabSearch.BackColor = [System.Drawing.Color]::LemonChiffon

$lblSearchPrompt          = New-Object System.Windows.Forms.Label
$lblSearchPrompt.Text     = "Hero Name:"
$lblSearchPrompt.Location = New-Object System.Drawing.Point(20, 20)
$lblSearchPrompt.AutoSize = $true

$txtSearchHero            = New-Object System.Windows.Forms.TextBox
$txtSearchHero.Location   = New-Object System.Drawing.Point(130, 18)
$txtSearchHero.Width      = 300

$btnSearch                = New-Object System.Windows.Forms.Button
$btnSearch.Text           = "Search"
$btnSearch.Location       = New-Object System.Drawing.Point(450, 15)
$btnSearch.Size           = New-Object System.Drawing.Size(90, 30)

$lblS_Hero                = New-Object System.Windows.Forms.Label
$lblS_Hero.Location       = New-Object System.Drawing.Point(20, 80)
$lblS_Hero.AutoSize       = $true

$lblS_Role                = New-Object System.Windows.Forms.Label
$lblS_Role.Location       = New-Object System.Drawing.Point(20, 120)
$lblS_Role.AutoSize       = $true

$lblS_Series              = New-Object System.Windows.Forms.Label
$lblS_Series.Location     = New-Object System.Drawing.Point(20, 160)
$lblS_Series.AutoSize     = $true

$lblS_Address             = New-Object System.Windows.Forms.Label
$lblS_Address.Location    = New-Object System.Drawing.Point(20, 200)
$lblS_Address.AutoSize    = $true

$lblS_Info                = New-Object System.Windows.Forms.Label
$lblS_Info.Location       = New-Object System.Drawing.Point(20, 240)
$lblS_Info.AutoSize       = $true

$btnS_Prev                = New-Object System.Windows.Forms.Button
$btnS_Prev.Text           = "< Previous"
$btnS_Prev.Location       = New-Object System.Drawing.Point(20, 280)
$btnS_Prev.Size           = New-Object System.Drawing.Size(100, 35)

$btnS_Next                = New-Object System.Windows.Forms.Button
$btnS_Next.Text           = "Next >"
$btnS_Next.Location       = New-Object System.Drawing.Point(140, 280)
$btnS_Next.Size           = New-Object System.Drawing.Size(100, 35)

$tabSearch.Controls.AddRange(@(
    $lblSearchPrompt,$txtSearchHero,$btnSearch,
    $lblS_Hero,$lblS_Role,$lblS_Series,$lblS_Address,$lblS_Info,
    $btnS_Prev,$btnS_Next
))

$tabs.TabPages.AddRange(@($tabAll,$tabSearch))
$form.Controls.Add($tabs)

# ---------- State ----------
$allRows   = Get-FlattenedActors
$allIndex  = 0
$searchRows = @()
$searchIndex = 0

# initial display for all actors
$allIndex = Show-RowOnLabels $allRows $allIndex $lblAllHero $lblAllRole $lblAllSeries $lblAllAddress $lblAllInfo

# ---------- Events ----------
$btnAllPrev.Add_Click({
    if ($allRows.Count -eq 0) { return }
    $allIndex--
    $allIndex = Show-RowOnLabels $allRows $allIndex $lblAllHero $lblAllRole $lblAllSeries $lblAllAddress $lblAllInfo
})

$btnAllNext.Add_Click({
    if ($allRows.Count -eq 0) { return }
    $allIndex++
    $allIndex = Show-RowOnLabels $allRows $allIndex $lblAllHero $lblAllRole $lblAllSeries $lblAllAddress $lblAllInfo
})

$btnSearch.Add_Click({
    $hero = $txtSearchHero.Text.Trim()
    if (-not $hero) {
        [System.Windows.Forms.MessageBox]::Show("Enter a heroName to search.","Info") | Out-Null
        return
    }

    $searchRows = Get-FlattenedActors -heroNameFilter $hero
    $searchIndex = 0
    if ($searchRows.Count -eq 0) {
        $lblS_Hero.Text    = "Hero: (none)"
        $lblS_Role.Text    = "Role: (none)"
        $lblS_Series.Text  = "Series/Movie: (none)"
        $lblS_Address.Text = "Address: (none)"
        $lblS_Info.Text    = "0 of 0"
        [System.Windows.Forms.MessageBox]::Show("No records found for '$hero'.","Info") | Out-Null
    } else {
        $searchIndex = Show-RowOnLabels $searchRows $searchIndex $lblS_Hero $lblS_Role $lblS_Series $lblS_Address $lblS_Info
    }
})

$btnS_Prev.Add_Click({
    if ($searchRows.Count -eq 0) { return }
    $searchIndex--
    $searchIndex = Show-RowOnLabels $searchRows $searchIndex $lblS_Hero $lblS_Role $lblS_Series $lblS_Address $lblS_Info
})

$btnS_Next.Add_Click({
    if ($searchRows.Count -eq 0) { return }
    $searchIndex++
    $searchIndex = Show-RowOnLabels $searchRows $searchIndex $lblS_Hero $lblS_Role $lblS_Series $lblS_Address $lblS_Info
})

[void]$form.ShowDialog()
