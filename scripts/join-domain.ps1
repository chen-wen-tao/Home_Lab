# Client domain join script
# Simplified version for Windows Server

$domain = "lab.local"
$dc_ip = "10.10.2.10"
$password = "MyStrongPassword123!"
$username = "labadmin"

# Configure DNS to point to DC
Write-Host "Configuring DNS to point to DC at $dc_ip..."
$adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $dc_ip
Write-Host "DNS configured."

# Flush DNS cache
Write-Host "Flushing DNS cache..."
Clear-DnsClientCache
Write-Host "DNS cache flushed."

# Wait for DC to be ready
Write-Host "Waiting for DC to be ready..."
$maxAttempts = 60
$attempt = 0
$dcReady = $false

while ($attempt -lt $maxAttempts -and -not $dcReady) {
    $attempt++
    Write-Host "Attempt $attempt/$maxAttempts : Checking DC connectivity..."
    
    # Test ping to DC
    if (Test-Connection -ComputerName $dc_ip -Count 1 -Quiet) {
        Write-Host "DC is reachable. Testing LDAP and Kerberos ports..."
        
        # Test LDAP port (389)
        $ldapTest = Test-NetConnection -ComputerName $dc_ip -Port 389 -WarningAction SilentlyContinue -InformationLevel Quiet
        $kerberosTest = Test-NetConnection -ComputerName $dc_ip -Port 88 -WarningAction SilentlyContinue -InformationLevel Quiet
        
        if ($ldapTest -and $kerberosTest) {
            $dcReady = $true
            Write-Host "DC is ready for domain join!"
        } else {
            Write-Host "DC ports not ready yet, waiting..."
            Start-Sleep -Seconds 5
        }
    } else {
        Write-Host "DC not reachable, waiting..."
        Start-Sleep -Seconds 5
    }
}

if (-not $dcReady) {
    Write-Error "DC is not ready after $maxAttempts attempts. Please check DC status and try again manually."
    exit 1
}

Write-Host "DC is ready! Attempting to join domain..."

# Create secure password
$secure = ConvertTo-SecureString $password -AsPlainText -Force

# Try different credential formats
$credentialFormats = @(
    "$username@$domain",
    "$domain\$username",
    $username
)

$joined = $false
foreach ($credFormat in $credentialFormats) {
    if ($joined) { break }
    
    Write-Host "Attempting to join domain $domain using credentials: $credFormat..."
    
    try {
        $cred = New-Object System.Management.Automation.PSCredential($credFormat, $secure)
        Add-Computer -DomainName $domain -Credential $cred -Restart -Force -ErrorAction Stop
        Write-Host "Successfully joined domain using $credFormat. System will restart..."
        $joined = $true
    } catch {
        Write-Host "Failed with $credFormat : $($_.Exception.Message)"
        if ($credFormat -eq $credentialFormats[-1]) {
            Write-Error "Failed to join domain with all credential formats. Error: $($_.Exception.Message)"
            exit 1
        }
    }
}
