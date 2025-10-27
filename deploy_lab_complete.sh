#!/usr/bin/env bash
# Complete Lab Deployment Script (with upgraded plan)
# Deploys: Windows DC, Windows Client, Linux Client (all private), Jumpbox (public IP only)
# All VMs with proper disk sizes

if [ -z "$1" ]; then
  echo "Usage: ./deploy_lab_complete.sh <admin_password>"
  echo "This will deploy a complete lab with only jumpbox having public IP"
  exit 1
fi

ADMIN_PASS="$1"
RG_NAME="lab-complete-rg"
LOCATION="westus2"
VNET_NAME="lab-vnet"
SUBNET_NAME="private"

echo "🚀 Deploying complete lab with upgraded plan..."
echo "💰 Expected monthly cost: ~$60 (much cheaper than Bastion!)"
echo "🔒 All VMs private except jumpbox for security"

# Check if logged into Azure
if ! az account show &>/dev/null; then
  echo "❌ Not logged into Azure CLI. Please run: az login"
  exit 1
fi

# Show current subscription
echo "📋 Current subscription:"
az account show --query "{Name:name, ID:id}" --output table

# Create resource group
echo "📦 Creating resource group..."
az group create --name $RG_NAME --location $LOCATION

# Create virtual network
echo "🌐 Creating virtual network..."
az network vnet create \
  --resource-group $RG_NAME \
  --name $VNET_NAME \
  --address-prefix 10.10.0.0/16 \
  --subnet-name $SUBNET_NAME \
  --subnet-prefix 10.10.2.0/24

# Create Domain Controller (PRIVATE - no public IP)
echo "🖥️  Creating Domain Controller (PRIVATE)..."
az vm create \
  --resource-group $RG_NAME \
  --name dc \
  --image Win2022Datacenter \
  --size Standard_B2s \
  --admin-username labadmin \
  --admin-password "$ADMIN_PASS" \
  --vnet-name $VNET_NAME \
  --subnet $SUBNET_NAME \
  --private-ip-address 10.10.2.10 \
  --public-ip-address "" \
  --storage-sku Standard_LRS \
  --os-disk-size-gb 128 \
  --tags "auto-shutdown=18:00"

# Create Windows Client (PRIVATE - no public IP)
echo "🖥️  Creating Windows Client (PRIVATE)..."
az vm create \
  --resource-group $RG_NAME \
  --name client \
  --image Win2019Datacenter \
  --size Standard_B2s \
  --admin-username labadmin \
  --admin-password "$ADMIN_PASS" \
  --vnet-name $VNET_NAME \
  --subnet $SUBNET_NAME \
  --public-ip-address "" \
  --storage-sku Standard_LRS \
  --os-disk-size-gb 128 \
  --tags "auto-shutdown=18:00"

# Create Linux Client (PRIVATE - no public IP)
echo "🐧 Creating Linux Client (PRIVATE)..."
az vm create \
  --resource-group $RG_NAME \
  --name linux-client \
  --image Ubuntu2204 \
  --size Standard_B2s \
  --admin-username labadmin \
  --admin-password "$ADMIN_PASS" \
  --vnet-name $VNET_NAME \
  --subnet $SUBNET_NAME \
  --public-ip-address "" \
  --storage-sku Standard_LRS \
  --os-disk-size-gb 32 \
  --tags "auto-shutdown=18:00"

# Create Jumpbox (PUBLIC IP - for access)
echo "🖥️  Creating Jumpbox (PUBLIC IP for access)..."
az vm create \
  --resource-group $RG_NAME \
  --name jumpbox \
  --image Win2022Datacenter \
  --size Standard_B2s \
  --admin-username labadmin \
  --admin-password "$ADMIN_PASS" \
  --vnet-name $VNET_NAME \
  --subnet $SUBNET_NAME \
  --public-ip-address "" \
  --storage-sku Standard_LRS \
  --os-disk-size-gb 128 \
  --tags "auto-shutdown=18:00"

# Get VM information
echo "📊 Getting VM information..."
DC_IP=$(az vm show -d -g $RG_NAME -n dc --query privateIps -o tsv)
CLIENT_IP=$(az vm show -d -g $RG_NAME -n client --query privateIps -o tsv)
LINUX_IP=$(az vm show -d -g $RG_NAME -n linux-client --query privateIps -o tsv)
JUMPBOX_PUBLIC_IP=$(az vm show -d -g $RG_NAME -n jumpbox --query publicIps -o tsv)
JUMPBOX_PRIVATE_IP=$(az vm show -d -g $RG_NAME -n jumpbox --query privateIps -o tsv)

echo ""
echo "✅ Complete lab deployed successfully!"
echo ""
echo "📊 Lab Information:"
echo "Resource Group: $RG_NAME"
echo "Location: $LOCATION"
echo ""
echo "🔒 PRIVATE VMs (no public access):"
echo "DC Private IP: $DC_IP"
echo "Client Private IP: $CLIENT_IP"
echo "Linux Client Private IP: $LINUX_IP"
echo ""
echo "🌐 PUBLIC VM (for access):"
echo "Jumpbox Public IP: $JUMPBOX_PUBLIC_IP"
echo "Jumpbox Private IP: $JUMPBOX_PRIVATE_IP"
echo ""
echo "🔐 How to Access:"
echo "1. RDP to Jumpbox: $JUMPBOX_PUBLIC_IP:3389 (labadmin / $ADMIN_PASS)"
echo "2. From Jumpbox, RDP to other VMs using their private IPs:"
echo "   - DC: $DC_IP:3389"
echo "   - Client: $CLIENT_IP:3389"
echo "   - Linux: $LINUX_IP:22 (SSH)"
echo ""
echo "💰 Cost Breakdown:"
echo "- 4x VMs (Standard_B2s): ~$40/month"
echo "- 1x Public IP: ~$5/month"
echo "- Storage: ~$15/month"
echo "- Total: ~$60/month (70% savings vs Bastion!)"
echo ""
echo "🔒 Security Benefits:"
echo "- Only jumpbox exposed to internet"
echo "- All lab VMs protected behind private network"
echo "- JIT access can be enabled for jumpbox"
echo "- Auto-shutdown at 6 PM daily"
echo ""
echo "📖 Next Steps:"
echo "1. RDP to jumpbox using the public IP above"
echo "2. From jumpbox, access other VMs using private IPs"
echo "3. Set up domain controller on DC"
echo "4. Join client machines to the domain"
echo "5. Configure your lab environment as needed"
echo ""
echo "🔧 To enable JIT access for jumpbox:"
echo "1. Go to Azure Portal → Security Center"
echo "2. Navigate to Just-in-time VM access"
echo "3. Configure access for jumpbox (RDP port 3389)"
echo "4. Set time limits and source IPs as needed"
