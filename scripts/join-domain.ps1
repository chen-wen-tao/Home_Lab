# Client auto-join (may run before DC is ready; run manually from bastion if needed)
$domain = "lab.local"
$dc_ip = "10.10.2.10"
$secure = ConvertTo-SecureString "Password" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential("labadmin",$secure)
Add-Computer -DomainName $domain -Credential $cred -Restart
