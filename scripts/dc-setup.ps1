# DC setup script (runs once via custom_data)
# WARNING: edit domain and password if reusing
$domain = "lab.local"
$adminPass = ConvertTo-SecureString "MyStrongPassword123!" -AsPlainText -Force
Install-WindowsFeature -Name AD-Domain-Services, DNS -IncludeManagementTools
Import-Module ADDSDeployment
Install-ADDSForest -DomainName $domain -SafeModeAdministratorPassword $adminPass -InstallDNS -Force
