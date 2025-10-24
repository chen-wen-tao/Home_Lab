output "bastion_public_ip" {
  value = azurerm_public_ip.bastion_pip.ip_address
}

output "dc_private_ip" {
  value = azurerm_network_interface.dc_nic.ip_configuration[0].private_ip_address
}
