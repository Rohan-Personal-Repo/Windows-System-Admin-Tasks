# Hide Build Number and Watermark from Desktop
Write-Host "Disabling desktop OS version watermark..." -ForegroundColor Cyan

# Set PaintDesktopVersion to 0 (disables desktop watermark)
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "PaintDesktopVersion" -Value 0

# Remove any 'Test Mode' or Evaluation watermark (if exists)
Write-Host "Checking for 'Test Mode' or evaluation mode settings..." -ForegroundColor Cyan

# Disable 'TestSigning' mode if enabled (requires admin)
$bcdEditOutput = bcdedit
if ($bcdEditOutput -match "testsigning\s+Yes") {
    Write-Host "Test Mode detected. Disabling..." -ForegroundColor Yellow
    bcdedit /set TESTSIGNING OFF | Out-Null
} else {
    Write-Host "Test Mode not enabled." -ForegroundColor Green
}

# Optionally disable 'nointegritychecks' (which can also show watermark)
if ($bcdEditOutput -match "nointegritychecks\s+Yes") {
    Write-Host "Disabling integrity checks..." -ForegroundColor Yellow
    bcdedit /set nointegritychecks OFF | Out-Null
}

# Restart Explorer to apply changes immediately
Write-Host "Restarting Explorer to apply changes..." -ForegroundColor Cyan
Stop-Process -Name explorer -Force
Start-Process explorer

Write-Host "`n Desktop watermark and version info should now be hidden." -ForegroundColor Green
