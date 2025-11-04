#!/usr/bin/env bash
# Terraform VM Management Script
# Start/stop VMs using Terraform

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
    echo "🚀 Starting all lab VMs using Azure REST API (bypassing CLI bug)..."
    
    # Get subscription ID
    SUBSCRIPTION_ID=$(az account show --query id -o tsv 2>/dev/null)
    if [ -z "$SUBSCRIPTION_ID" ]; then
      echo "❌ Could not get subscription ID. Please run: az login"
      exit 1
    fi
    
    STARTED_COUNT=0
    for vm in "${VMS[@]}"; do
      echo "Starting $vm..."
      # Use REST API directly to bypass Azure CLI bug
      VM_RESOURCE_ID="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Compute/virtualMachines/$vm"
      
      if az rest --method POST \
        --uri "https://management.azure.com$VM_RESOURCE_ID/start?api-version=2023-03-01" \
        --headers "Content-Type=application/json" &>/dev/null; then
        echo "  ✓ $vm is starting"
        STARTED_COUNT=$((STARTED_COUNT + 1))
      else
        echo "  ⚠ Failed to start $vm"
      fi
    done
    
    if [ $STARTED_COUNT -gt 0 ]; then
      echo "✅ $STARTED_COUNT VM(s) are starting up..."
      echo "⏳ Wait 2-3 minutes for VMs to be fully ready"
    else
      echo "⚠️  Some VMs may have failed to start. Check status with: ./terraform_vm_manage.sh status"
    fi
    ;;
    
  "stop")
    echo "🛑 Stopping all lab VMs using Azure REST API (bypassing CLI bug)..."
    
    # Get subscription ID
    SUBSCRIPTION_ID=$(az account show --query id -o tsv 2>/dev/null)
    if [ -z "$SUBSCRIPTION_ID" ]; then
      echo "❌ Could not get subscription ID. Please run: az login"
      exit 1
    fi
    
    STOPPED_COUNT=0
    for vm in "${VMS[@]}"; do
      echo "Stopping $vm..."
      # Use REST API directly to bypass Azure CLI bug
      VM_RESOURCE_ID="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Compute/virtualMachines/$vm"
      
      # First stop the VM, then deallocate it
      if az rest --method POST \
        --uri "https://management.azure.com$VM_RESOURCE_ID/deallocate?api-version=2023-03-01" \
        --headers "Content-Type=application/json" &>/dev/null; then
        echo "  ✓ $vm is being deallocated"
        STOPPED_COUNT=$((STOPPED_COUNT + 1))
      else
        # Fallback: try stop first, then deallocate
        echo "  ⚠ Trying alternative method for $vm..."
        az rest --method POST \
          --uri "https://management.azure.com$VM_RESOURCE_ID/powerOff?api-version=2023-03-01" \
          --headers "Content-Type=application/json" &>/dev/null
        sleep 2
        az rest --method POST \
          --uri "https://management.azure.com$VM_RESOURCE_ID/deallocate?api-version=2023-03-01" \
          --headers "Content-Type=application/json" &>/dev/null && STOPPED_COUNT=$((STOPPED_COUNT + 1))
      fi
    done
    
    if [ $STOPPED_COUNT -gt 0 ]; then
      echo "✅ $STOPPED_COUNT VM(s) are being stopped/deallocated..."
      echo "💰 You're now saving ~$40/month on compute costs!"
    else
      echo "⚠️  Some VMs may have failed to stop. Check status with: ./terraform_vm_manage.sh status"
    fi
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
    
  "terraform-start")
    echo "🚀 Starting VMs using Terraform..."
    cd terraform
    # Use null_resource to trigger VM start
    terraform apply -target=null_resource.start_vms -auto-approve
    ;;
    
  "terraform-stop")
    echo "🛑 Stopping VMs using Terraform..."
    cd terraform
    # Use null_resource to trigger VM stop
    terraform apply -target=null_resource.stop_vms -auto-approve
    ;;
    
  *)
    echo "Usage: ./terraform_vm_manage.sh [start|stop|status|terraform-start|terraform-stop]"
    echo ""
    echo "Commands:"
    echo "  start           - Start all VMs (Azure CLI - fast)"
    echo "  stop            - Stop all VMs (Azure CLI - fast)"
    echo "  status          - Show VM status"
    echo "  terraform-start - Start VMs using Terraform"
    echo "  terraform-stop  - Stop VMs using Terraform"
    echo ""
    echo "💡 Recommendation: Use 'start' and 'stop' for daily use"
    echo "   Use 'terraform-start/stop' for infrastructure management"
    exit 1
    ;;
esac
