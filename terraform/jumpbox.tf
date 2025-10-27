# Jumpbox VM with public IP

# Public IP for jumpbox
resource "azurerm_public_ip" "jumpbox" {
  name                = "${var.prefix}-jumpbox-pip"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = "Lab"
    Purpose     = "Jumpbox"
  }
}

# Network interface for jumpbox
resource "azurerm_network_interface" "jumpbox" {
  name                = "${var.prefix}-jumpbox-nic"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jumpbox.id
  }

  tags = {
    Environment = "Lab"
    Purpose     = "Jumpbox"
  }
}

# Jumpbox VM
resource "azurerm_windows_virtual_machine" "jumpbox" {
  name                = "${var.prefix}-jumpbox"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.jumpbox.id,
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
    Purpose         = "Jumpbox"
    auto-shutdown   = var.auto_shutdown_time
  }
}
