# Ansible Deployment Playbooks

This directory contains Ansible playbooks for deploying MSSQL, Apache, and Nginx services to your Azure lab infrastructure.

## 📁 Directory Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── requirements.yml         # Ansible collections requirements
├── site.yml                 # Master playbook (deploys all services)
├── deploy-mssql.yml         # MSSQL Server deployment playbook
├── deploy-apache.yml        # Apache Web Server deployment playbook
├── deploy-nginx.yml         # Nginx Web Server deployment playbook
├── inventory/
│   └── hosts.yml           # Inventory file (hosts definition)
├── group_vars/
│   ├── all/
│   │   └── vault.yml       # Encrypted passwords (Ansible Vault)
│   ├── windows.yml         # Windows group variables
│   └── linux.yml           # Linux group variables
├── host_vars/              # Host-specific variables (optional)
├── templates/              # Jinja2 templates for configuration files
├── setup-vault.sh          # Helper script to create vault
├── update-inventory.sh     # Helper script to update inventory from Terraform
├── test-winrm.sh           # Helper script to test Windows connectivity
└── test-linux.sh           # Helper script to test Linux connectivity
```

## 🚀 Quick Start

### Prerequisites

1. **Ansible installed** on your local machine (or jumpbox):
   ```bash
   sudo apt update
   sudo apt install ansible -y
   # OR
   pip3 install ansible
   ```

2. **Terraform infrastructure deployed** and VMs are running:
   ```bash
   cd terraform
   terraform output  # Verify VMs are running
   ```

3. **Windows WinRM enabled** (if not already configured):
   - Connect to Windows VM via RDP
   - Run: `winrm quickconfig`

### Step 1: Install Ansible Collections

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
```

### Step 2: Update Inventory with IP Addresses

**Option A: Use the update script (recommended)**
```bash
./update-inventory.sh
```

**Option B: Manual update**
1. Get IP addresses from Terraform:
   ```bash
   cd ../terraform
   terraform output
   ```
2. Edit `inventory/hosts.yml` and replace placeholder IPs with actual values

### Step 3: Set Passwords

**Option A: Using Ansible Vault (recommended)**

Create the vault file:
```bash
./setup-vault.sh
```

Or manually:
```bash
ansible-vault create group_vars/all/vault.yml
```

Add the following content:
```yaml
vault_admin_password: "YourAdminPassword123!"
vault_mssql_sa_password: "YourMSSQLSAPassword123!"
```

**Option B: Command line (less secure)**
```bash
ansible-playbook site.yml \
  --extra-vars "vault_admin_password=YourPassword vault_mssql_sa_password=YourMSSQLPassword"
```

### Step 4: Test Connectivity

```bash
# Test Windows connection
ansible windows -m win_ping --ask-vault-pass

# Test Linux connection
ansible linux -m ping --ask-vault-pass
```

Or use the helper scripts:
```bash
./test-winrm.sh
./test-linux.sh
```

### Step 5: Deploy Services

**Deploy all services:**
```bash
ansible-playbook site.yml --ask-vault-pass
```

**Deploy individually:**
```bash
# MSSQL only
ansible-playbook deploy-mssql.yml --ask-vault-pass

# Apache only
ansible-playbook deploy-apache.yml --ask-vault-pass

# Nginx only
ansible-playbook deploy-nginx.yml --ask-vault-pass
```

## 📋 Playbook Details

### MSSQL Server Deployment (`deploy-mssql.yml`)

**Target:** Windows Client VM  
**Features:**
- Downloads and installs SQL Server 2022 Express
- Configures SQL Server instance
- Sets up SA password
- Enables TCP/IP protocol
- Configures Windows Firewall
- Creates data directories (D:\MSSQL\*)

**Configuration:**
- Instance Name: `MSSQLSERVER` (default)
- Port: `1433` (default)
- SA Password: Set via vault or `--extra-vars`

**Service Port:** `1433` (Windows Client VM)

### Apache Web Server Deployment (`deploy-apache.yml`)

**Target:** Linux VM  
**Features:**
- Installs Apache HTTP Server
- Enables required modules (rewrite, ssl, headers, deflate, expires)
- Creates default website with custom HTML
- Configures security headers
- Sets up firewall rules

**Configuration:**
- Port: `80` (default)
- Document Root: `/var/www/html`
- SSL Port: `443` (configured, not enabled by default)

**Service Port:** `80` (Linux VM)

### Nginx Web Server Deployment (`deploy-nginx.yml`)

**Target:** Linux VM  
**Features:**
- Installs Nginx web server
- Creates separate document root (`/var/www/nginx`)
- Configures security headers
- Optimizes worker processes and connections
- Sets up firewall rules

**Configuration:**
- Port: `8080` (default, different from Apache to avoid conflicts)
- Document Root: `/var/www/nginx`
- SSL Port: `8443` (configured, not enabled by default)

**Service Port:** `8080` (Linux VM)

## 🔐 Password Management

### Changing Passwords in Ansible Vault

**Edit the vault file:**
```bash
ansible-vault edit group_vars/all/vault.yml
```

You'll be prompted for the vault password, then you can edit:
```yaml
vault_admin_password: "YourCurrentPassword"
vault_mssql_sa_password: "YourCurrentMSSQLPassword"
```

**View current passwords:**
```bash
ansible-vault view group_vars/all/vault.yml
```

**Recreate vault file:**
```bash
./setup-vault.sh
```

### Important Notes

1. **Vault Password vs VM Password:**
   - **Vault password**: Used to encrypt/decrypt the vault file (you'll be prompted for this when running playbooks)
   - **VM password**: The actual password for `labadmin` user on VMs (stored as `vault_admin_password`)

2. **Password Must Match Terraform:**
   - The `vault_admin_password` must match the `admin_password` you used in Terraform
   - If you change the VM password, you need to update it in Terraform too, or change it on the VMs directly

3. **After Changing Password:**
   Test the connection:
   ```bash
   ansible linux -m ping --ask-vault-pass
   ansible windows -m win_ping --ask-vault-pass
   ```

## 🔧 Configuration

### Inventory File

The inventory file (`inventory/hosts.yml`) defines your hosts. Update IP addresses after Terraform deployment:

```yaml
windows:
  hosts:
    client:
      ansible_host: 10.10.2.XX  # Update with actual IP
```

### Group Variables

- **`group_vars/windows.yml`**: Windows-specific variables (MSSQL settings)
- **`group_vars/linux.yml`**: Linux-specific variables (Apache/Nginx settings)
- **`group_vars/all/vault.yml`**: Encrypted passwords (Ansible Vault)

### Customization

You can override defaults by:
1. Editing `group_vars/*.yml` files
2. Creating `host_vars/<hostname>.yml` for host-specific overrides
3. Using `--extra-vars` on the command line

## 🧪 Verification

After deployment, verify services:

**MSSQL (from Windows VM):**
```powershell
Test-NetConnection -ComputerName localhost -Port 1433
```

**Apache (from Linux VM or jumpbox):**
```bash
curl http://<linux-ip>:80
```

**Nginx (from Linux VM or jumpbox):**
```bash
curl http://<linux-ip>:8080
```

## 📝 Troubleshooting

### Connection Issues

**Windows (WinRM):**
```bash
# Test WinRM connection
ansible windows -m win_ping --ask-vault-pass

# If connection fails:
# 1. Ensure WinRM is enabled on Windows: winrm quickconfig
# 2. Check firewall rules
# 3. Verify credentials
```

**Linux (SSH):**
```bash
# Test SSH connection
ansible linux -m ping --ask-vault-pass

# If connection fails:
# 1. Ensure SSH is enabled
# 2. Check firewall rules
# 3. Verify credentials and sudo access
```

### MSSQL Installation Issues

- Installation can take 15-30 minutes
- Ensure the Windows VM has sufficient disk space (D:\ drive recommended)
- Check Windows Event Viewer for installation logs
- Verify the installer file was downloaded correctly (should be >100MB)

### Apache/Nginx Conflicts

- Apache runs on port 80
- Nginx runs on port 8080 (intentionally different to avoid conflicts)
- Both can run simultaneously on the same Linux VM

### Password Issues

If you forgot the vault password:
- Recreate the vault file using `./setup-vault.sh`
- Or delete the vault file and create a new one

If password doesn't work after changing:
- Verify the password matches what's on the VM
- Check if you're using the correct vault password
- Test SSH manually: `ssh labadmin@<linux-ip>`

## 🔒 Security Notes

1. **Passwords**: Use Ansible Vault for password management (recommended)
2. **WinRM**: Currently configured with `server_cert_validation: ignore` (not for production)
3. **Firewall**: Firewall rules are configured automatically
4. **Security Headers**: Both Apache and Nginx include security headers

## 📚 Additional Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Windows Guide](https://docs.ansible.com/ansible/latest/os_guide/windows.html)
- [SQL Server Installation Guide](https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server)
- [Apache Documentation](https://httpd.apache.org/docs/)
- [Nginx Documentation](https://nginx.org/en/docs/)
