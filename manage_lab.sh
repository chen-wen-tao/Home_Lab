#!/usr/bin/env bash
# Lab Management Script
# Start, stop, or check status of your lab VMs

RG_NAME="lab-complete-rg"
VMS=("dc" "client" "linux-client" "jumpbox")

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
    az vm list --resource-group $RG_NAME --query "[].{Name:name, Status:powerState, PublicIP:publicIps, PrivateIP:privateIps}" --output table
    echo ""
    echo "💡 Status meanings:"
    echo "  - 'VM running' = You're being charged compute costs"
    echo "  - 'VM deallocated' = No compute charges (saving money!)"
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
