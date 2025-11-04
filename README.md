# Home Lab - Azure Infrastructure

## 🚀 Quick Start

### Deploy the Lab
```bash
./terraform_manage.sh apply YourSecurePassword123!
```

### Get VM Information
```bash
./terraform_manage.sh output
```

### Manage VMs
```bash
# Check VM status
./terraform_vm_manage.sh status

# Start all VMs
./terraform_vm_manage.sh start

# Stop all VMs (save money)
./terraform_vm_manage.sh stop
```

## 📁 Project Structure

### Essential Scripts
- **`terraform_manage.sh`** - Main Terraform management (deploy, destroy, plan, output)
- **`terraform_vm_manage.sh`** - VM lifecycle management (start, stop, status)
- **`manage_lab.sh`** - Alternative lab management (legacy, use terraform_vm_manage.sh)

### Terraform Configuration (`terraform/` directory)
- `main.tf` - Networking and security configuration
- `variables.tf` - All configurable variables
- `outputs.tf` - Deployment outputs (IPs, access info)
- `dc.tf` - Domain Controller VM
- `client.tf` - Windows Client VM
- `linux.tf` - Linux Client VM
- `jumpbox.tf` - Jumpbox VM (with public IP)

### PowerShell Scripts (`scripts/` directory)
- `dc-setup.ps1` - Domain Controller setup script
- `join-domain.ps1` - Client domain join script

### Ansible Automation (`ansible/` directory)
- **`site.yml`** - Master playbook (deploys all services)
- **`deploy-mssql.yml`** - MSSQL Server deployment playbook
- **`deploy-nginx.yml`** - Nginx Web Server deployment playbook
- **`deploy-apache.yml`** - Apache Web Server deployment playbook
- **`update-inventory.sh`** - Updates Ansible inventory from Terraform outputs
- See `ansible/README.md` for detailed Ansible documentation

### Documentation
- **`README.md`** - This file (quick reference)
- **`TROUBLESHOOTING.md`** - Common issues and solutions

## 🏗️ Lab Architecture

- **Resource Group**: `lab-complete-rg` (or configurable)
- **Location**: West US 2 (default)
- **Network**: Virtual Network `10.10.0.0/16`, Subnet `10.10.2.0/24`

### 4 Virtual Machines:
1. **Domain Controller** (`lab-dc`) - Windows Server 2022, Private IP: `10.10.2.10`
2. **Windows Client** (`lab-client`) - Windows Server 2019, Private
3. **Linux Client** (`lab-linux`) - Ubuntu 22.04, Private
4. **Jumpbox** (`lab-jumpbox`) - Windows Server 2022, **Public IP** (for access)

## 🔐 Access Instructions

After deployment, get connection info:
```bash
./terraform_manage.sh output
```

1. **RDP to Jumpbox** using the public IP shown in output
   - Username: `labadmin`
   - Password: (the one you used during deployment)

2. **From Jumpbox, access other VMs** using private IPs:
   - DC: `10.10.2.10:3389`
   - Client: (private IP from output):3389
   - Linux: (private IP from output):22 (SSH)

## 💰 Cost Management

- **VMs Running**: ~$60/month
  - Compute: ~$40/month (4x Standard_B2s)
  - Storage: ~$15/month
  - Public IP: ~$5/month
- **VMs Stopped**: ~$20/month (storage + IP only)
- **Savings**: ~$40/month (67%) when stopped

**Auto-shutdown**: All VMs shut down at 6 PM daily to save costs.

## 🔒 Security Features
- Only jumpbox exposed to internet
- All lab VMs protected behind private network
- Network Security Group with RDP/SSH rules
- Auto-shutdown at 6 PM daily

## 📖 Common Commands

### Terraform Management
```bash
./terraform_manage.sh init          # Initialize Terraform
./terraform_manage.sh plan          # Preview changes
./terraform_manage.sh apply <pass>   # Deploy infrastructure
./terraform_manage.sh destroy       # Remove all resources
./terraform_manage.sh output        # Show VM IPs and info
./terraform_manage.sh status        # Show current status
```

### VM Management
```bash
./terraform_vm_manage.sh start      # Start all VMs
./terraform_vm_manage.sh stop       # Stop all VMs (save money)
./terraform_vm_manage.sh status     # Check VM status
```

## 🤖 Ansible Automation

After deploying your infrastructure with Terraform, use Ansible to automate service deployment and configuration.

### Quick Start with Ansible

1. **Install Ansible** (if not already installed):
   ```bash
   sudo apt install ansible -y
   # OR
   pip3 install ansible
   ```

2. **Navigate to Ansible directory**:
   ```bash
   cd ansible
   ```

3. **Install Ansible collections**:
   ```bash
   ansible-galaxy collection install -r requirements.yml
   ```

4. **Update inventory from Terraform**:
   ```bash
   ./update-inventory.sh
   ```

5. **Set up Ansible Vault** (for secure password management):
   ```bash
   ./setup-vault.sh
   ```

6. **Deploy services**:
   ```bash
   # Deploy all services (MSSQL, Apache, Nginx)
   ansible-playbook site.yml --ask-vault-pass

   # Or deploy individually
   ansible-playbook deploy-mssql.yml --ask-vault-pass    # MSSQL on Windows Client
   ansible-playbook deploy-apache.yml --ask-vault-pass   # Apache on Linux
   ansible-playbook deploy-nginx.yml --ask-vault-pass    # Nginx on Linux
   ```

### What Ansible Deploys

- **MSSQL Server 2022 Express** on Windows Client VM (port 1433)
- **Apache Web Server** on Linux VM (port 80)
- **Nginx Web Server** on Linux VM (port 8080)

For detailed Ansible documentation, see `ansible/README.md`.

## 🔧 Troubleshooting

See `TROUBLESHOOTING.md` for:
- Azure CLI compatibility issues
- Subscription read-only errors
- Terraform import/state issues
- Common deployment problems

## 📖 Next Steps

1. Deploy the lab: `./terraform_manage.sh apply <password>`
2. Get access info: `./terraform_manage.sh output`
3. RDP to jumpbox using the public IP
4. Configure domain controller
5. Join client machines to domain
6. **Deploy services with Ansible**: `cd ansible && ansible-playbook site.yml --ask-vault-pass`
7. Use `./terraform_vm_manage.sh stop` when done to save money
