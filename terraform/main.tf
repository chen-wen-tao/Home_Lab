# Main Terraform configuration
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Use existing resource group (data source) or create new one
# This allows using existing RGs when subscription is read-only
data "azurerm_resource_group" "lab" {
  count = var.use_existing_resource_group ? 1 : 0
  name  = var.resource_group_name
}

resource "azurerm_resource_group" "lab" {
  count    = var.use_existing_resource_group ? 0 : 1
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = "Lab"
    Purpose     = "Home Lab"
  }
}

# Local value to use the correct resource group reference
locals {
  resource_group_name = var.use_existing_resource_group ? data.azurerm_resource_group.lab[0].name : azurerm_resource_group.lab[0].name
  resource_group_location = var.use_existing_resource_group ? data.azurerm_resource_group.lab[0].location : azurerm_resource_group.lab[0].location
}

# Virtual Network
resource "azurerm_virtual_network" "lab" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.10.0.0/16"]
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name

  tags = {
    Environment = "Lab"
  }
}

# Subnet
resource "azurerm_subnet" "private" {
  name                 = "private"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.10.2.0/24"]
}

# Network Security Group
resource "azurerm_network_security_group" "lab" {
  name                = "${var.prefix}-nsg"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name

  # Allow RDP from jumpbox subnet
  security_rule {
    name                       = "AllowRDPFromJumpbox"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "10.10.2.0/24"
    destination_address_prefix = "*"
  }

  # Allow SSH from jumpbox subnet
  security_rule {
    name                       = "AllowSSHFromJumpbox"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.10.2.0/24"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = "Lab"
  }
}

# Associate NSG with subnet
resource "azurerm_subnet_network_security_group_association" "lab" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.lab.id
}
