# JIT (Just-in-Time) Access Lab - No Public IPs Needed
# Uses Azure Security Center JIT access - completely free!

# -------------------------
# Resource Group & Network
# -------------------------
resource "azurerm_resource_group" "lab" {
  name     = var.rg_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "lab-vnet"
  resource_group_name = azurerm_resource_group.lab.name
  location            = var.location
  address_space       = ["${var.prefix}.0.0/16"]
}

# Private subnet for VMs
resource "azurerm_subnet" "private" {
  name                 = "private"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["${var.prefix}.2.0/24"]
}

# -------------------------
# Domain Controller NIC (private static)
# -------------------------
resource "azurerm_network_interface" "dc_nic" {
  name                = "dc-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.prefix}.2.10"
  }
}

# Domain Controller VM (Windows Server 2022)
resource "azurerm_windows_virtual_machine" "dc" {
  name                  = "dc"
  location              = var.location
  resource_group_name   = azurerm_resource_group.lab.name
  size                  = "Standard_B1s"
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.dc_nic.id]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 64
  }

  # Auto-shutdown at 6 PM
  tags = {
    "auto-shutdown" = "18:00"
  }

  custom_data = filebase64("${path.module}/scripts/dc-setup.ps1")
}

# -------------------------
# Client NIC (private)
# -------------------------
resource "azurerm_network_interface" "client_nic" {
  name                = "client-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Client VM (Windows Server 2019 as workstation)
resource "azurerm_windows_virtual_machine" "client" {
  name                  = "client"
  location              = var.location
  resource_group_name   = azurerm_resource_group.lab.name
  size                  = "Standard_B1s"
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.client_nic.id]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 64
  }

  # Auto-shutdown at 6 PM
  tags = {
    "auto-shutdown" = "18:00"
  }
}

# -------------------------
# Linux Target NIC (private)
# -------------------------
resource "azurerm_network_interface" "linux_nic" {
  name                = "linux-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Linux Target VM (Ubuntu 22.04 LTS)
resource "azurerm_linux_virtual_machine" "linux_target" {
  name                            = "linux-target"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.lab.name
  size                            = "Standard_B1s"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.linux_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb        = 32
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # Auto-shutdown at 6 PM
  tags = {
    "auto-shutdown" = "18:00"
  }
}
