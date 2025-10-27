# Linux Client VM (private)

# Network interface for linux client
resource "azurerm_network_interface" "linux" {
  name                = "${var.prefix}-linux-nic"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Environment = "Lab"
    Purpose     = "Linux Client"
  }
}

# Linux Client VM
resource "azurerm_linux_virtual_machine" "linux" {
  name                = "${var.prefix}-linux"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.linux.id,
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 32
  }

  tags = {
    Environment     = "Lab"
    Purpose         = "Linux Client"
    auto-shutdown   = var.auto_shutdown_time
  }
}
