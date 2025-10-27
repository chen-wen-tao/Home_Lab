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
    echo "🏗️  Applying Terraform configuration..."
    terraform apply -var="admin_password=$2" -auto-approve
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
    echo "Usage: ./terraform_manage.sh [init|plan|apply|destroy|output|status|add-vm]"
    echo ""
    echo "Commands:"
    echo "  init                    - Initialize Terraform"
    echo "  plan                    - Show planned changes"
    echo "  apply <password>        - Deploy/update infrastructure"
    echo "  destroy                 - Destroy infrastructure"
    echo "  output                  - Show infrastructure outputs"
    echo "  status                  - Show current status"
    echo "  add-vm <name>           - Create template for new VM"
    echo ""
    echo "Examples:"
    echo "  ./terraform_manage.sh init"
    echo "  ./terraform_manage.sh apply MyPassword123!"
    echo "  ./terraform_manage.sh add-vm webserver"
    exit 1
    ;;
esac
