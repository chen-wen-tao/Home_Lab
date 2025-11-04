#!/usr/bin/env bash
# Lab Management Script
# Start, stop, or check status of your lab VMs

# Try to detect resource group name from Terraform or use default
RG_NAME="${RESOURCE_GROUP_NAME:-lab-complete-rg}"
VMS=("lab-dc" "lab-client" "lab-linux" "lab-jumpbox")

# Check if we're using a different resource group (from Terraform state)
if [ -f "terraform/terraform.tfstate" ]; then
  DETECTED_RG=$(cd terraform && terraform show -json 2>/dev/null | grep -o '"resource_group_name":"[^"]*"' | head -1 | cut -d'"' -f4)
  if [ -n "$DETECTED_RG" ]; then
    RG_NAME="$DETECTED_RG"
  fi
fi

case "$1" in
  "start")
    echo "🚀 Starting all lab VMs..."
    for vm in "${VMS[@]}"; do
      echo "Starting $vm..."
      az vm start --resource-group $RG_NAME --name $vm --no-wait
    done
    echo "✅ All VMs are starting up..."
    echo "⏳ Wait 2-3 minutes for VMs to be fully ready"
    ;;
    
  "stop")
    echo "🛑 Stopping all lab VMs..."
    for vm in "${VMS[@]}"; do
      echo "Stopping $vm..."
      az vm deallocate --resource-group $RG_NAME --name $vm --no-wait
    done
    echo "✅ All VMs are being stopped..."
    echo "💰 You're now saving ~$40/month on compute costs!"
    ;;
    
  "status")
    echo "📊 Lab VM Status:"
    echo ""
    
    # Check if resource group exists
    if ! az group show --name $RG_NAME &>/dev/null; then
      echo "⚠️  Resource group '$RG_NAME' does not exist."
      echo "💡 VMs may not be deployed yet. Run: ./terraform_manage.sh apply <password>"
      exit 0
    fi
    
    # Use alternative method to avoid Azure CLI 'disks' attribute error
    # Check VMs individually instead of using az vm list
    printf "%-15s %-20s %-15s %-15s\n" "Name" "Status" "Public IP" "Private IP"
    echo "------------------------------------------------------------------------"
    
    for vm in "${VMS[@]}"; do
      # Get VM power state using resource API (avoids disks attribute error)
      POWER_STATE=$(az vm show --resource-group $RG_NAME --name $vm --show-details --query "powerState" -o tsv 2>/dev/null || echo "Unknown")
      
      # Get IPs using network interface (more reliable)
      NIC_ID=$(az vm show --resource-group $RG_NAME --name $vm --query "networkProfile.networkInterfaces[0].id" -o tsv 2>/dev/null)
      if [ -n "$NIC_ID" ]; then
        PRIVATE_IP=$(az network nic show --ids "$NIC_ID" --query "ipConfigurations[0].privateIpAddress" -o tsv 2>/dev/null || echo "N/A")
        PIP_ID=$(az network nic show --ids "$NIC_ID" --query "ipConfigurations[0].publicIpAddress.id" -o tsv 2>/dev/null)
        if [ -n "$PIP_ID" ] && [ "$PIP_ID" != "null" ]; then
          PUBLIC_IP=$(az network public-ip show --ids "$PIP_ID" --query "ipAddress" -o tsv 2>/dev/null || echo "N/A")
        else
          PUBLIC_IP="N/A"
        fi
      else
        PRIVATE_IP="N/A"
        PUBLIC_IP="N/A"
      fi
      
      # Format status nicely
      if echo "$POWER_STATE" | grep -q "running"; then
        STATUS="🟢 Running"
      elif echo "$POWER_STATE" | grep -q "deallocated"; then
        STATUS="🔴 Stopped"
      else
        STATUS="$POWER_STATE"
      fi
      
      printf "%-15s %-20s %-15s %-15s\n" "$vm" "$STATUS" "$PUBLIC_IP" "$PRIVATE_IP"
    done
    
    echo ""
    echo "💡 Status meanings:"
    echo "  - 🟢 Running = You're being charged compute costs"
    echo "  - 🔴 Stopped = No compute charges (saving money!)"
    ;;
    
  "cost")
    echo "💰 Current Lab Costs:"
    echo ""
    echo "🟢 Always charged (even when stopped):"
    echo "  - Storage: ~$15/month"
    echo "  - Public IP: ~$5/month"
    echo "  - Total fixed: ~$20/month"
    echo ""
    echo "🔴 Only when VMs are running:"
    echo "  - Compute (4x Standard_B2s): ~$40/month"
    echo ""
    echo "💡 Total costs:"
    echo "  - VMs running: ~$60/month"
    echo "  - VMs stopped: ~$20/month"
    echo "  - Savings when stopped: ~$40/month (67%!)"
    ;;
    
  "jumpbox-only")
    echo "🖥️  Starting only jumpbox (for quick access)..."
    az vm start --resource-group $RG_NAME --name jumpbox
    echo "✅ Jumpbox is starting..."
    echo "🔐 RDP to: 4.155.27.12:3389 (labadmin / MyStrongPassword123!)"
    ;;
    
  *)
    echo "Usage: ./manage_lab.sh [start|stop|status|cost|jumpbox-only]"
    echo ""
    echo "Commands:"
    echo "  start         - Start all VMs (costs ~$60/month)"
    echo "  stop          - Stop all VMs (saves ~$40/month)"
    echo "  status        - Show current VM status"
    echo "  cost          - Show cost breakdown"
    echo "  jumpbox-only  - Start only jumpbox for quick access"
    echo ""
    echo "💡 Pro tip: Use 'stop' when done for the day to save money!"
    exit 1
    ;;
esac
