#!/usr/bin/env bash
# Terraform Lab Management Script
# Manages the lab infrastructure using Terraform

cd terraform

case "$1" in
  "init")
    echo "🚀 Initializing Terraform..."
    terraform init
    ;;
    
  "plan")
    echo "📋 Planning Terraform changes..."
    terraform plan
    ;;
    
  "apply")
    if [ -z "$2" ]; then
      echo "Usage: ./terraform_manage.sh apply <admin_password>"
      exit 1
    fi
    
    # Pre-flight checks
    echo "🔍 Pre-flight checks..."
    
    # Check Azure login
    if ! az account show &>/dev/null; then
      echo "❌ Not logged into Azure. Please run: az login"
      exit 1
    fi
    
    # Check subscription status
    SUBSCRIPTION_STATE=$(az account show --query state -o tsv 2>/dev/null)
    SUBSCRIPTION_ID=$(az account show --query id -o tsv 2>/dev/null)
    
    if [ "$SUBSCRIPTION_STATE" != "Enabled" ]; then
      echo "❌ Subscription is not enabled (State: $SUBSCRIPTION_STATE)"
      echo "💡 Please enable your subscription in Azure Portal or contact support"
      exit 1
    fi
    
    # Try a test resource group creation to check for read-only issues
    TEST_RG="terraform-test-$(date +%s)"
    echo "🧪 Testing subscription write access..."
    if az group create --name "$TEST_RG" --location "westus2" &>/dev/null; then
      echo "✅ Subscription is writable"
      az group delete --name "$TEST_RG" --yes &>/dev/null
    else
      TEST_ERROR=$(az group create --name "$TEST_RG" --location "westus2" 2>&1)
      if echo "$TEST_ERROR" | grep -q "ReadOnlyDisabledSubscription"; then
        echo "❌ Subscription is in read-only mode despite showing as Enabled"
        echo "💡 This usually means:"
        echo "   1. Subscription was recently enabled and needs time to propagate"
        echo "   2. Spending limit is active (remove in Azure Portal)"
        echo "   3. Subscription has restrictions"
        echo ""
        echo "🔧 Solutions:"
        echo "   - Wait 5-10 minutes and try again"
        echo "   - Check Azure Portal → Subscriptions → Your subscription"
        echo "   - Remove spending limit if active"
        echo "   - Contact Azure support"
        exit 1
      fi
    fi
    
    echo "🏗️  Applying Terraform configuration..."
    
    # Try normal apply first, but catch read-only errors and retry with existing RG
    echo "📝 Attempting deployment with new resource group..."
    TERRAFORM_OUTPUT=$(terraform apply -var="admin_password=$2" -auto-approve 2>&1)
    TERRAFORM_EXIT=$?
    echo "$TERRAFORM_OUTPUT"
    
    if [ $TERRAFORM_EXIT -eq 0 ]; then
      echo "✅ Deployment successful!"
    else
      # Check if error is due to read-only subscription
      if echo "$TERRAFORM_OUTPUT" | grep -q "ReadOnlyDisabledSubscription"; then
        echo ""
        echo "❌ Subscription is read-only. Cannot create resources."
        echo ""
        echo "💡 Options:"
        echo "   1. Wait 10-15 minutes for subscription permissions to propagate"
        echo "   2. Check Azure Portal to ensure subscription is enabled"
        echo "   3. Contact Azure Support if issue persists"
        echo ""
        echo "⚠️  Note: Cannot use existing resource groups because subscription is read-only"
        echo "   (Even using existing RGs requires write permissions to create resources)"
        exit 1
      else
        echo "❌ Deployment failed. Check the error above."
        exit 1
      fi
    fi
    ;;
    
  "destroy")
    echo "💥 Destroying lab infrastructure..."
    terraform destroy -auto-approve
    ;;
    
  "output")
    echo "📊 Lab Information:"
    terraform output
    ;;
    
  "status")
    echo "📋 Current Infrastructure Status:"
    terraform show -json | jq -r '.values.root_module.resources[] | select(.type == "azurerm_windows_virtual_machine" or .type == "azurerm_linux_virtual_machine") | "\(.name): \(.values.name)"'
    ;;
    
  "import")
    if [ -z "$2" ] || [ -z "$3" ]; then
      echo "Usage: ./terraform_manage.sh import <resource_type> <resource_id>"
      echo "Example: ./terraform_manage.sh import azurerm_resource_group.lab /subscriptions/xxx/resourceGroups/lab-complete-rg"
      echo ""
      echo "Common imports:"
      echo "  Resource Group: ./terraform_manage.sh import azurerm_resource_group.lab /subscriptions/SUBSCRIPTION_ID/resourceGroups/RESOURCE_GROUP_NAME"
      echo ""
      echo "To find resource IDs, use Azure CLI:"
      echo "  az group show --name <rg-name> --query id -o tsv"
      exit 1
    fi
    echo "📥 Importing existing resource into Terraform state..."
    echo "Resource: $2"
    echo "ID: $3"
    terraform import "$2" "$3"
    ;;
    
  "import-rg")
    if [ -z "$2" ]; then
      echo "Usage: ./terraform_manage.sh import-rg <resource_group_name>"
      echo "Example: ./terraform_manage.sh import-rg lab-complete-rg"
      exit 1
    fi
    echo "📥 Importing existing resource group into Terraform state..."
    RG_NAME="$2"
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    if [ -z "$SUBSCRIPTION_ID" ]; then
      echo "❌ Could not get subscription ID. Are you logged in?"
      exit 1
    fi
    RESOURCE_ID="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME"
    echo "Importing: azurerm_resource_group.lab -> $RESOURCE_ID"
    terraform import azurerm_resource_group.lab "$RESOURCE_ID"
    ;;
    
  "add-vm")
    if [ -z "$2" ]; then
      echo "Usage: ./terraform_manage.sh add-vm <vm_name>"
      echo "Example: ./terraform_manage.sh add-vm webserver"
      exit 1
    fi
    echo "➕ Adding new VM: $2"
    echo "1. Create a new .tf file for your VM"
    echo "2. Run: terraform plan"
    echo "3. Run: terraform apply"
    echo ""
    echo "Example VM template created: new-vm.tf.template"
    cat > "new-vm.tf.template" << 'EOF'
# New VM Template
resource "azurerm_network_interface" "NEW_VM_NAME" {
  name                = "${var.prefix}-NEW_VM_NAME-nic"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Environment = "Lab"
    Purpose     = "NEW_VM_PURPOSE"
  }
}

resource "azurerm_windows_virtual_machine" "NEW_VM_NAME" {
  name                = "${var.prefix}-NEW_VM_NAME"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.NEW_VM_NAME.id,
  ]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 128
  }

  tags = {
    Environment     = "Lab"
    Purpose         = "NEW_VM_PURPOSE"
    auto-shutdown   = var.auto_shutdown_time
  }
}
EOF
    echo "Template created! Edit it and rename to your VM name."
    ;;
    
  *)
    echo "Usage: ./terraform_manage.sh [init|plan|apply|destroy|output|status|import|import-rg|add-vm]"
    echo ""
    echo "Commands:"
    echo "  init                    - Initialize Terraform"
    echo "  plan                    - Show planned changes"
    echo "  apply <password>        - Deploy/update infrastructure"
    echo "  destroy                 - Destroy infrastructure"
    echo "  output                  - Show infrastructure outputs"
    echo "  status                  - Show current status"
    echo "  import <type.id> <id>   - Import existing resource"
    echo "  import-rg <rg-name>     - Import existing resource group (quick helper)"
    echo "  add-vm <name>           - Create template for new VM"
    echo ""
    echo "Examples:"
    echo "  ./terraform_manage.sh init"
    echo "  ./terraform_manage.sh apply MyPassword123!"
    echo "  ./terraform_manage.sh import-rg lab-complete-rg  # Import existing resource group"
    echo "  ./terraform_manage.sh add-vm webserver"
    exit 1
    ;;
esac
