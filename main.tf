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

# Private subnet for your VMs
resource "azurerm_subnet" "private" {
  name                 = "private"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["${var.prefix}.2.0/24"]
}

# Azure Bastion requires a dedicated subnet named exactly AzureBastionSubnet (at least /27)
resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["${var.prefix}.3.0/27"]
}

# -------------------------
# Azure Bastion Host (policy-friendly: no NIC has a public IP)
# -------------------------
resource "azurerm_public_ip" "bastion_pip" {
  name                = "bastion-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                = "lab-bastion"
  location            = var.location
  resource_group_name = var.rg_name

  sku                    = "Standard"
  scale_units            = 2
  tunneling_enabled      = true
  ip_connect_enabled     = true
  copy_paste_enabled     = true
  file_copy_enabled      = true
  shareable_link_enabled = false

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
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
  size                  = "Standard_B1ms"
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
    disk_size_gb         = 128
  }

  # optional bootstrap for AD promotion; requires scripts/dc-setup.ps1 present
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
  size                  = "Standard_B1ms"
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
    disk_size_gb         = 128
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
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy" # Ubuntu 22.04 LTS (Jammy)
    sku       = "22_04-lts"
    version   = "latest"
  }
}
