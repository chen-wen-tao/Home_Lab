# Domain Controller VM (private)

# Network interface for DC
resource "azurerm_network_interface" "dc" {
  name                = "${var.prefix}-dc-nic"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.10.2.10"
  }

  tags = {
    Environment = "Lab"
    Purpose     = "Domain Controller"
  }
}

# DC VM
resource "azurerm_windows_virtual_machine" "dc" {
  name                = "${var.prefix}-dc"
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.dc.id,
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

  # Custom data for DC setup
  custom_data = base64encode(file("${path.module}/../scripts/dc-setup.ps1"))

  tags = {
    Environment     = "Lab"
    Purpose         = "Domain Controller"
    auto-shutdown   = var.auto_shutdown_time
  }
}
