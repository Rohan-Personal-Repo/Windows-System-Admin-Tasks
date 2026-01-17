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

    return ,$rows  # always an array
}

function Show-RowOnLabels {
    param(
        $rows,                    # no type constraint, no @() wrapping
        [int]$index,
        $lblHeroHead, $lblHeroVal,
        $lblRoleHead, $lblRoleVal,
        $lblSeriesHead, $lblSeriesVal,
        $lblAddrHead, $lblAddrVal,
        $lblInfo
    )

    if (-not $rows) {
        $lblHeroVal.Text   = "(none)"
        $lblRoleVal.Text   = "(none)"
        $lblSeriesVal.Text = "(none)"
        $lblAddrVal.Text   = "(none)"
        $lblInfo.Text      = "0 of 0"
        return 0
    }

    # ensure we can count and index
    $count = ($rows | Measure-Object).Count
    if ($count -eq 0) {
        $lblHeroVal.Text   = "(none)"
        $lblRoleVal.Text   = "(none)"
        $lblSeriesVal.Text = "(none)"
        $lblAddrVal.Text   = "(none)"
        $lblInfo.Text      = "0 of 0"
        return 0
    }

    if ($index -lt 0) { $index = 0 }
    if ($index -ge $count) { $index = $count - 1 }

    $row = $rows[$index]

    $lblHeroVal.Text   = "  " + [string]$row.HeroName
    $lblRoleVal.Text   = "  " + [string]$row.RoleName
    $lblSeriesVal.Text = "  " + [string]$row.SeriesMovieTitle
    $lblAddrVal.Text   = "  " + [string]$row.Address
    $lblInfo.Text      = "Record {0} of {1}" -f ($index + 1), $count

    return $index
}


# ---------- Fonts ----------
$fontHeading = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$fontValue   = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Italic)

# ---------- UI shell ----------
$form               = New-Object System.Windows.Forms.Form
$form.Text          = "Actors Viewer (MongoDB + Mdbc)"
$form.Size          = New-Object System.Drawing.Size(1200, 700)
$form.MinimumSize   = New-Object System.Drawing.Size(1024, 600)
$form.StartPosition = "CenterScreen"
$form.BackColor     = [System.Drawing.Color]::LemonChiffon
$form.Font          = New-Object System.Drawing.Font("Segoe UI", 11)
$form.ForeColor     = [System.Drawing.Color]::Purple

$tabs               = New-Object System.Windows.Forms.TabControl
$tabs.Location      = New-Object System.Drawing.Point(10, 10)
$tabs.Size          = New-Object System.Drawing.Size(1160, 640)
$tabs.Anchor        = "Top,Bottom,Left,Right"

# ================= Tab 1: All Actors =================
$tabAll             = New-Object System.Windows.Forms.TabPage
$tabAll.Text        = "All Actors"
$tabAll.BackColor   = [System.Drawing.Color]::LemonChiffon

$btnAllPrev         = New-Object System.Windows.Forms.Button
$btnAllPrev.Text    = "< Previous"
$btnAllPrev.Location= New-Object System.Drawing.Point(20, 260)
$btnAllPrev.Size    = New-Object System.Drawing.Size(120, 35)

$btnAllNext         = New-Object System.Windows.Forms.Button
$btnAllNext.Text    = "Next >"
$btnAllNext.Location= New-Object System.Drawing.Point(160, 260)
$btnAllNext.Size    = New-Object System.Drawing.Size(120, 35)

$lblAllInfo         = New-Object System.Windows.Forms.Label
$lblAllInfo.Location= New-Object System.Drawing.Point(320, 265)
$lblAllInfo.AutoSize= $true

$lblAllHeroHead                = New-Object System.Windows.Forms.Label
$lblAllHeroHead.Text           = "Hero:"
$lblAllHeroHead.Location       = New-Object System.Drawing.Point(20, 40)
$lblAllHeroHead.AutoSize       = $true
$lblAllHeroHead.Font           = $fontHeading

$lblAllHeroVal                 = New-Object System.Windows.Forms.Label
$lblAllHeroVal.Location        = New-Object System.Drawing.Point(120, 40)
$lblAllHeroVal.AutoSize        = $true
$lblAllHeroVal.Font            = $fontValue

$lblAllRoleHead                = New-Object System.Windows.Forms.Label
$lblAllRoleHead.Text           = "Role:"
$lblAllRoleHead.Location       = New-Object System.Drawing.Point(20, 80)
$lblAllRoleHead.AutoSize       = $true
$lblAllRoleHead.Font           = $fontHeading

$lblAllRoleVal                 = New-Object System.Windows.Forms.Label
$lblAllRoleVal.Location        = New-Object System.Drawing.Point(120, 80)
$lblAllRoleVal.AutoSize        = $true
$lblAllRoleVal.Font            = $fontValue

$lblAllSeriesHead              = New-Object System.Windows.Forms.Label
$lblAllSeriesHead.Text         = "Series/Movie:"
$lblAllSeriesHead.Location     = New-Object System.Drawing.Point(20, 120)
$lblAllSeriesHead.AutoSize     = $true
$lblAllSeriesHead.Font         = $fontHeading

$lblAllSeriesVal               = New-Object System.Windows.Forms.Label
$lblAllSeriesVal.Location      = New-Object System.Drawing.Point(160, 120)
$lblAllSeriesVal.AutoSize      = $true
$lblAllSeriesVal.Font          = $fontValue

$lblAllAddrHead                = New-Object System.Windows.Forms.Label
$lblAllAddrHead.Text           = "Address:"
$lblAllAddrHead.Location       = New-Object System.Drawing.Point(20, 160)
$lblAllAddrHead.AutoSize       = $true
$lblAllAddrHead.Font           = $fontHeading

$lblAllAddrVal                 = New-Object System.Windows.Forms.Label
$lblAllAddrVal.Location        = New-Object System.Drawing.Point(160, 160)
$lblAllAddrVal.AutoSize        = $true
$lblAllAddrVal.Font            = $fontValue

$tabAll.Controls.AddRange(@(
    $lblAllHeroHead,$lblAllHeroVal,
    $lblAllRoleHead,$lblAllRoleVal,
    $lblAllSeriesHead,$lblAllSeriesVal,
    $lblAllAddrHead,$lblAllAddrVal,
    $btnAllPrev,$btnAllNext,$lblAllInfo
))

# ================= Tab 2: Search =================
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

$lblS_HeroHead            = New-Object System.Windows.Forms.Label
$lblS_HeroHead.Text       = "Hero:"
$lblS_HeroHead.Location   = New-Object System.Drawing.Point(20, 80)
$lblS_HeroHead.AutoSize   = $true
$lblS_HeroHead.Font       = $fontHeading

$lblS_HeroVal             = New-Object System.Windows.Forms.Label
$lblS_HeroVal.Location    = New-Object System.Drawing.Point(120, 80)
$lblS_HeroVal.AutoSize    = $true
$lblS_HeroVal.Font        = $fontValue

$lblS_RoleHead            = New-Object System.Windows.Forms.Label
$lblS_RoleHead.Text       = "Role:"
$lblS_RoleHead.Location   = New-Object System.Drawing.Point(20, 120)
$lblS_RoleHead.AutoSize   = $true
$lblS_RoleHead.Font       = $fontHeading

$lblS_RoleVal             = New-Object System.Windows.Forms.Label
$lblS_RoleVal.Location    = New-Object System.Drawing.Point(120, 120)
$lblS_RoleVal.AutoSize    = $true
$lblS_RoleVal.Font        = $fontValue

$lblS_SeriesHead          = New-Object System.Windows.Forms.Label
$lblS_SeriesHead.Text     = "Series/Movie:"
$lblS_SeriesHead.Location = New-Object System.Drawing.Point(20, 160)
$lblS_SeriesHead.AutoSize = $true
$lblS_SeriesHead.Font     = $fontHeading

$lblS_SeriesVal           = New-Object System.Windows.Forms.Label
$lblS_SeriesVal.Location  = New-Object System.Drawing.Point(160, 160)
$lblS_SeriesVal.AutoSize  = $true
$lblS_SeriesVal.Font      = $fontValue

$lblS_AddrHead            = New-Object System.Windows.Forms.Label
$lblS_AddrHead.Text       = "Address:"
$lblS_AddrHead.Location   = New-Object System.Drawing.Point(20, 200)
$lblS_AddrHead.AutoSize   = $true
$lblS_AddrHead.Font       = $fontHeading

$lblS_AddrVal             = New-Object System.Windows.Forms.Label
$lblS_AddrVal.Location    = New-Object System.Drawing.Point(160, 200)
$lblS_AddrVal.AutoSize    = $true
$lblS_AddrVal.Font        = $fontValue

$lblS_Info                = New-Object System.Windows.Forms.Label
$lblS_Info.Location       = New-Object System.Drawing.Point(20, 240)
$lblS_Info.AutoSize       = $true

$btnS_Prev                = New-Object System.Windows.Forms.Button
$btnS_Prev.Text           = "< Previous"
$btnS_Prev.Location       = New-Object System.Drawing.Point(20, 280)
$btnS_Prev.Size           = New-Object System.Drawing.Size(120, 35)

$btnS_Next                = New-Object System.Windows.Forms.Button
$btnS_Next.Text           = "Next >"
$btnS_Next.Location       = New-Object System.Drawing.Point(160, 280)
$btnS_Next.Size           = New-Object System.Drawing.Size(120, 35)

$tabSearch.Controls.AddRange(@(
    $lblSearchPrompt,$txtSearchHero,$btnSearch,
    $lblS_HeroHead,$lblS_HeroVal,
    $lblS_RoleHead,$lblS_RoleVal,
    $lblS_SeriesHead,$lblS_SeriesVal,
    $lblS_AddrHead,$lblS_AddrVal,
    $lblS_Info,
    $btnS_Prev,$btnS_Next
))

$tabs.TabPages.AddRange(@($tabAll,$tabSearch))
$form.Controls.Add($tabs)

# ---------- State ----------
$allRows    = Get-FlattenedActors
$allIndex   = 0
$searchRows = @()
$searchIndex = 0

$allIndex = Show-RowOnLabels $allRows $allIndex `
    $lblAllHeroHead $lblAllHeroVal `
    $lblAllRoleHead $lblAllRoleVal `
    $lblAllSeriesHead $lblAllSeriesVal `
    $lblAllAddrHead $lblAllAddrVal `
    $lblAllInfo

# ---------- Events ----------
$btnAllPrev.Add_Click({
    if ($allRows.Count -eq 0) { return }
    $allIndex--
    $allIndex = Show-RowOnLabels $allRows $allIndex `
        $lblAllHeroHead $lblAllHeroVal `
        $lblAllRoleHead $lblAllRoleVal `
        $lblAllSeriesHead $lblAllSeriesVal `
        $lblAllAddrHead $lblAllAddrVal `
        $lblAllInfo
})

$btnAllNext.Add_Click({
    if ($allRows.Count -eq 0) { return }
    $allIndex++
    $allIndex = Show-RowOnLabels $allRows $allIndex `
        $lblAllHeroHead $lblAllHeroVal `
        $lblAllRoleHead $lblAllRoleVal `
        $lblAllSeriesHead $lblAllSeriesVal `
        $lblAllAddrHead $lblAllAddrVal `
        $lblAllInfo
})

$btnSearch.Add_Click({
    $hero = $txtSearchHero.Text.Trim()
    if (-not $hero) {
        [System.Windows.Forms.MessageBox]::Show("Enter a heroName to search.","Info") | Out-Null
        return
    }

    $searchRows  = Get-FlattenedActors -heroNameFilter $hero
    $searchIndex = 0

    if ($searchRows.Count -eq 0) {
        $lblS_HeroVal.Text   = "  (none)"
        $lblS_RoleVal.Text   = "  (none)"
        $lblS_SeriesVal.Text = "  (none)"
        $lblS_AddrVal.Text   = "  (none)"
        $lblS_Info.Text      = "0 of 0"
        [System.Windows.Forms.MessageBox]::Show("No records found for '$hero'.","Info") | Out-Null
    } else {
        $searchIndex = Show-RowOnLabels $searchRows $searchIndex `
            $lblS_HeroHead $lblS_HeroVal `
            $lblS_RoleHead $lblS_RoleVal `
            $lblS_SeriesHead $lblS_SeriesVal `
            $lblS_AddrHead $lblS_AddrVal `
            $lblS_Info
    }
})

$btnS_Prev.Add_Click({
    if ($searchRows.Count -eq 0) { return }
    $searchIndex--
    $searchIndex = Show-RowOnLabels $searchRows $searchIndex `
        $lblS_HeroHead $lblS_HeroVal `
        $lblS_RoleHead $lblS_RoleVal `
        $lblS_SeriesHead $lblS_SeriesVal `
        $lblS_AddrHead $lblS_AddrVal `
        $lblS_Info
})

$btnS_Next.Add_Click({
    if ($searchRows.Count -eq 0) { return }
    $searchIndex++
    $searchIndex = Show-RowOnLabels $searchRows $searchIndex `
        $lblS_HeroHead $lblS_HeroVal `
        $lblS_RoleHead $lblS_RoleVal `
        $lblS_SeriesHead $lblS_SeriesVal `
        $lblS_AddrHead $lblS_AddrVal `
        $lblS_Info
})

[void]$form.ShowDialog()
