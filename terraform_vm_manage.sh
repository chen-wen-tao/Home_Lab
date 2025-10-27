#!/usr/bin/env bash
# Terraform VM Management Script
# Start/stop VMs using Terraform

RG_NAME="lab-complete-rg"
VMS=("dc" "client" "linux-client" "jumpbox")

case "$1" in
  "start")
    echo "🚀 Starting all lab VMs using Azure CLI..."
    for vm in "${VMS[@]}"; do
      echo "Starting $vm..."
      az vm start --resource-group $RG_NAME --name $vm --no-wait
    done
    echo "✅ All VMs are starting up..."
    echo "⏳ Wait 2-3 minutes for VMs to be fully ready"
    ;;
    
  "stop")
    echo "🛑 Stopping all lab VMs using Azure CLI..."
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
    az vm list --resource-group $RG_NAME --query "[].{Name:name, Status:powerState, PublicIP:publicIps, PrivateIP:privateIps}" --output table
    echo ""
    echo "💡 Status meanings:"
    echo "  - 'VM running' = You're being charged compute costs"
    echo "  - 'VM deallocated' = No compute charges (saving money!)"
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
