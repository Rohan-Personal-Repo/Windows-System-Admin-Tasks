Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "PaintDesktopVersion" -Value 1
Stop-Process -Name explorer -Force
Start-Process explorer
