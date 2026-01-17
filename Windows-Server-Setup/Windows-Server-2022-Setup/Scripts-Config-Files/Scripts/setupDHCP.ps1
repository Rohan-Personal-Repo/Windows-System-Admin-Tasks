# ================================
# DHCP Server Setup
# Scope: 192.168.1.0/24
# Range: 192.168.1.100–150
# ================================

Write-Host "Installing DHCP role..." -ForegroundColor Cyan
Install-WindowsFeature DHCP -IncludeManagementTools

Write-Host "Authorizing DHCP in AD..."
Add-DhcpServerInDC -DnsName $env:COMPUTERNAME -IPAddress (Get-NetIPAddress -AddressFamily IPv4).IPAddress

Write-Host "Creating DHCP scope..."
Add-DhcpServerv4Scope `
    -Name "LAB-SCOPE" `
    -StartRange 192.168.1.100 `
    -EndRange 192.168.1.150 `
    -SubnetMask 255.255.255.0

Write-Host "Adding DNS option..."
Set-DhcpServerv4OptionValue -DnsServer 192.168.1.10 -DnsDomain lab.local

Write-Host "DHCP Setup Complete!" -ForegroundColor Green
