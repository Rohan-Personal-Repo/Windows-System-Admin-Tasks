# ================================
# Windows Server 2022 Demo Script
# Automates basic SysAdmin tasks
# ================================

Write-Host "Starting Windows Server demo..." -ForegroundColor Cyan

# 1. Create local folders
Write-Host "Creating demo folders..."
New-Item -ItemType Directory -Path "C:\Demo" -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path "C:\Demo\Logs" -ErrorAction SilentlyContinue

# 2. Create a user (local user if not a DC)
Write-Host "Creating local user demo_user..."
$Password = ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force
New-LocalUser -Name "demo_user" -Password $Password -FullName "Demo User" -Description "Created by PowerShell Demo"

# 3. Add user to local Administrators group
Add-LocalGroupMember -Group "Administrators" -Member "demo_user"

# 4. Create a simple IIS website (if IIS is installed)
if (Get-WindowsFeature -Name Web-Server).Installed {
    Write-Host "Creating IIS website..."
    New-Item "C:\inetpub\demo_site" -ItemType Directory -ErrorAction SilentlyContinue
    Set-Content "C:\inetpub\demo_site\index.html" "<h1>Hello from Windows Server 2022!</h1>"
    
    Import-Module WebAdministration
    New-WebSite -Name "DemoSite" -Port 8080 -PhysicalPath "C:\inetpub\demo_site" -Force
}

# 5. Show basic system info
Write-Host "`nSystem Information:"
Get-ComputerInfo | Select-Object CsName, WindowsVersion, WindowsBuildLabEx

Write-Host "`nDemo Completed Successfully!" -ForegroundColor Green
