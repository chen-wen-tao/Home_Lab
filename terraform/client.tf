# Windows Client VM (private)

# Network interface for client
resource "azurerm_network_interface" "client" {
  name                = "${var.prefix}-client-nic"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Environment = "Lab"
    Purpose     = "Windows Client"
  }
}

# Client VM
resource "azurerm_windows_virtual_machine" "client" {
  name                = "${var.prefix}-client"
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.client.id,
  ]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-datacenter"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 128
  }

  # Custom data for domain join
  custom_data = base64encode(file("${path.module}/../scripts/join-domain.ps1"))

  tags = {
    Environment     = "Lab"
    Purpose         = "Windows Client"
    auto-shutdown   = var.auto_shutdown_time
  }
}
