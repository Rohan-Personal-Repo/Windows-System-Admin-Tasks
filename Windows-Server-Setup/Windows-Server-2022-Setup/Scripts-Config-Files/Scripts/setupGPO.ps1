# ================================
# GPO Demo Script
# Policy Name: LAB-POLICY
# ================================

Import-Module GroupPolicy

Write-Host "Creating new GPO..."
$gpo = New-GPO -Name "LAB-POLICY" -Comment "Demo GPO for lab"

Write-Host "Linking GPO to domain..."
New-GPLink -Name "LAB-POLICY" -Target "DC=lab,DC=local"

# 1. Password Policy
Write-Host "Configuring password policy..."
Set-GPRegistryValue -Name "LAB-POLICY" -Key "HKLM\Software\Policies\Microsoft\Windows\System" `
    -ValueName "MinimumPasswordLength" -Type DWord -Value 10

# 2. Disable USB Storage
Write-Host "Disabling USB storage..."
Set-GPRegistryValue -Name "LAB-POLICY" -Key "HKLM\SYSTEM\CurrentControlSet\Services\USBSTOR" `
    -ValueName "Start" -Type DWord -Value 4

# 3. Set Desktop Wallpaper
Write-Host "Setting wallpaper..."
Set-GPRegistryValue -Name "LAB-POLICY" `
    -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
    -ValueName "Wallpaper" -Type String -Value "C:\Windows\Web\Wallpaper\Windows\img0.jpg"

Write-Host "GPO setup complete!" -ForegroundColor Green
