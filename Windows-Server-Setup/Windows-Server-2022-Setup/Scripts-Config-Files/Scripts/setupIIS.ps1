# ================================
# IIS Auto-Deployment
# ================================

Write-Host "Installing IIS..." -ForegroundColor Cyan
Install-WindowsFeature Web-Server -IncludeManagementTools

Write-Host "Creating site folder..."
New-Item "C:\inetpub\demo_site" -ItemType Directory -Force

Write-Host "Creating demo index.html..."
Set-Content "C:\inetpub\demo_site\index.html" "<h1>Hello from Windows Server 2022 Demo Site!</h1>"

Write-Host "Creating IIS website..."
Import-Module WebAdministration
New-WebSite `
    -Name "DemoSite" `
    -Port 8080 `
    -PhysicalPath "C:\inetpub\demo_site" `
    -Force

Write-Host "IIS Deployment Complete!" -ForegroundColor Green
