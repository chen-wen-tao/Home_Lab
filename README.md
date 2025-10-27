# Home Lab - Azure Infrastructure

## 🏗️ Current Lab Setup
- **Resource Group**: `lab-complete-rg`
- **Location**: West US 2
- **Architecture**: Jumpbox with public IP + 3 private VMs

## 🖥️ Lab VMs
- **Jumpbox** (Public): `4.155.27.12` - Windows Server 2022
- **DC** (Private): `10.10.2.10` - Windows Server 2022 (Domain Controller)
- **Client** (Private): `10.10.2.4` - Windows Server 2019
- **Linux** (Private): `10.10.2.5` - Ubuntu 22.04

## 🔐 Access Instructions
1. **RDP to Jumpbox**: `4.155.27.12:3389`
   - Username: `labadmin`
   - Password: `MyStrongPassword123!`
2. **From Jumpbox, access other VMs**:
   - DC: `10.10.2.10:3389`
   - Client: `10.10.2.4:3389`
   - Linux: `10.10.2.5:22` (SSH)

## 📁 Essential Files

### Lab Management
- `manage_lab.sh` - **Main script** to start/stop/check lab status
- `deploy_lab_complete.sh` - Deploy the complete lab infrastructure
- `destroy_lab.sh` - Destroy the lab infrastructure

### Terraform Configuration
- `main.tf` - Main infrastructure configuration
- `variables.tf` - Variable definitions
- `outputs.tf` - Output values
- `provider.tf` - Azure provider configuration

### PowerShell Scripts
- `scripts/dc-setup.ps1` - Domain Controller setup script
- `scripts/join-domain.ps1` - Client domain join script

### Cost Management
- `CostManagement_Azure subscription 1_2025-10-23-1510.xlsx` - Cost analysis file

## 💰 Cost Management
- **VMs Running**: ~$60/month
- **VMs Stopped**: ~$20/month
- **Savings**: ~$40/month (67%) when stopped

### Quick Commands
```bash
# Check lab status
./manage_lab.sh status

# Start all VMs
./manage_lab.sh start

# Stop all VMs (save money)
./manage_lab.sh stop

# Start only jumpbox for quick access
./manage_lab.sh jumpbox-only

# View cost breakdown
./manage_lab.sh cost
```

## 🔒 Security Features
- Only jumpbox exposed to internet
- All lab VMs protected behind private network
- Auto-shutdown at 6 PM daily
- JIT access can be enabled for jumpbox

## 📖 Next Steps
1. Test access to jumpbox
2. Configure domain controller
3. Join client machines to domain
4. Set up your lab environment
5. Use `./manage_lab.sh stop` when done to save money
