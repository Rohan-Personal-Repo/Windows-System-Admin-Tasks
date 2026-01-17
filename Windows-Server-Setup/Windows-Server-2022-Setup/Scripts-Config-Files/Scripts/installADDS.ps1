# ================================
# Install AD DS & Create Domain
# Domain: lab.local
# ================================

Write-Host "Installing AD DS role..." -ForegroundColor Cyan
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

Write-Host "Promoting server to Domain Controller..." -ForegroundColor Yellow
Install-ADDSForest `
    -DomainName "lab.local" `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force) `
    -DomainNetbiosName "LAB" `
    -Force

Write-Host "Rebooting to complete AD DS installation..." -ForegroundColor Green
Restart-Computer
