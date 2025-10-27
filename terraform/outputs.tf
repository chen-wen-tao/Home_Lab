# Outputs for the lab infrastructure

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.lab.name
}

output "location" {
  description = "Location of the resources"
  value       = azurerm_resource_group.lab.location
}

output "jumpbox_public_ip" {
  description = "Public IP address of the jumpbox"
  value       = azurerm_public_ip.jumpbox.ip_address
}

output "jumpbox_private_ip" {
  description = "Private IP address of the jumpbox"
  value       = azurerm_network_interface.jumpbox.private_ip_address
}

output "dc_private_ip" {
  description = "Private IP address of the domain controller"
  value       = azurerm_network_interface.dc.private_ip_address
}

output "client_private_ip" {
  description = "Private IP address of the client VM"
  value       = azurerm_network_interface.client.private_ip_address
}

output "linux_private_ip" {
  description = "Private IP address of the linux VM"
  value       = azurerm_network_interface.linux.private_ip_address
}

output "access_instructions" {
  description = "Instructions for accessing the lab"
  value = <<-EOT
    Lab Access Instructions:
    ======================
    
    1. RDP to Jumpbox: ${azurerm_public_ip.jumpbox.ip_address}:3389
       Username: ${var.admin_username}
       Password: [as configured]
    
    2. From Jumpbox, access other VMs:
       - DC: ${azurerm_network_interface.dc.private_ip_address}:3389
       - Client: ${azurerm_network_interface.client.private_ip_address}:3389
       - Linux: ${azurerm_network_interface.linux.private_ip_address}:22 (SSH)
    
    3. All VMs auto-shutdown at ${var.auto_shutdown_time} daily
  EOT
}
