# WinRM Setup Script for Ansible
# This script configures WinRM for remote management

Write-Host "Configuring WinRM for Ansible..." -ForegroundColor Green

# Enable WinRM service
Enable-PSRemoting -Force -SkipNetworkProfileCheck

# Configure WinRM to accept HTTP connections (for lab/testing)
winrm quickconfig -force -q

# Set WinRM service to start automatically
Set-Service -Name WinRM -StartupType Automatic
Start-Service WinRM

# Configure WinRM listeners
winrm delete winrm/config/Listener?Address=*+Transport=HTTP 2>$null
winrm create winrm/config/Listener?Address=*+Transport=HTTP

# Allow unencrypted traffic (for lab environment only)
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/client '@{AllowUnencrypted="true"}'

# Configure firewall rules
netsh advfirewall firewall add rule name="WinRM HTTP" dir=in action=allow protocol=TCP localport=5985

Write-Host "WinRM configuration completed!" -ForegroundColor Green
Write-Host "WinRM is listening on port 5985" -ForegroundColor Yellow

# Display WinRM configuration
Write-Host "`nWinRM Configuration:" -ForegroundColor Cyan
winrm get winrm/config/service
winrm get winrm/config/client

Write-Host "`nTo test from Ansible, run: ansible windows -m win_ping" -ForegroundColor Yellow

