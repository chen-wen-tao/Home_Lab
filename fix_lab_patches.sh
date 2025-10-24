#!/usr/bin/env bash
# Run this inside ~/azure-lab to patch your main.tf in place

# 1️⃣ Switch Bastion IP to Standard SKU
sed -i '/resource "azurerm_public_ip" "bastion_ip"/,/^}/c\
resource "azurerm_public_ip" "bastion_ip" {\n  name                = "bastion-ip"\n  location            = var.location\n  resource_group_name = azurerm_resource_group.lab.name\n  allocation_method   = "Static"\n  sku                 = "Standard"\n}' main.tf

# 2️⃣ Fix DC disk size to >= image default (128 GB)
sed -i '/resource "azurerm_windows_virtual_machine" "dc"/,/^}/ s/disk_size_gb.*/disk_size_gb         = 128/' main.tf

# 3️⃣ Replace Windows 10 client with Windows Server 2019
awk '
/resource "azurerm_windows_virtual_machine" "client"/,/^}/{
  if ($0 ~ /resource/) print "resource \"azurerm_windows_virtual_machine\" \"client\" {\n  name = \"client\"\n  location = var.location\n  resource_group_name = azurerm_resource_group.lab.name\n  size = \"Standard_B2ms\"\n  admin_username = var.admin_username\n  admin_password = var.admin_password\n  network_interface_ids = [azurerm_network_interface.client_nic.id]\n\n  source_image_reference {\n    publisher = \"MicrosoftWindowsServer\"\n    offer     = \"WindowsServer\"\n    sku       = \"2019-Datacenter\"\n    version   = \"latest\"\n  }\n\n  os_disk {\n    caching              = \"ReadWrite\"\n    storage_account_type = \"Standard_LRS\"\n    disk_size_gb         = 128\n  }\n\n}"; next
}
{print}
' main.tf > tmp && mv tmp main.tf

# 4️⃣ Allow password SSH on both Linux VMs
sed -i '/resource "azurerm_linux_virtual_machine" "bastion"/,/^}/ s/admin_password.*/&\n  disable_password_authentication  = false/' main.tf
sed -i '/resource "azurerm_linux_virtual_machine" "linux_target"/,/^}/ s/admin_password.*/&\n  disable_password_authentication  = false/' main.tf

echo "✅ All patches applied. Next run:"
echo "terraform fmt && terraform validate && terraform apply -auto-approve -var=\"admin_password=My\$trongP@ssw0rd!\""
