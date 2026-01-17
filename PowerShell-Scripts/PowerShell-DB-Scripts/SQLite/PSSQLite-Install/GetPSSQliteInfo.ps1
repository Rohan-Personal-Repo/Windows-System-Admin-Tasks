# Clear the Screen
Clear-Host

# Import the PSSQlite module
Import-Module PSSQLite -Verbose

# Get Commands in the Module
Get-Command -Module PSSQLite

# Get Help for a Particular Command
Get-Help Invoke-SqliteQuery -Full