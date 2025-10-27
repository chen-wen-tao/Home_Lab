output "dc_private_ip" {
  value = azurerm_network_interface.dc_nic.ip_configuration[0].private_ip_address
  description = "Domain Controller private IP address"
}

output "client_private_ip" {
  value = azurerm_network_interface.client_nic.ip_configuration[0].private_ip_address
  description = "Client VM private IP address"
}

output "linux_private_ip" {
  value = azurerm_network_interface.linux_nic.ip_configuration[0].private_ip_address
  description = "Linux VM private IP address"
}

output "jit_access_instructions" {
  value = "1. Go to Azure Portal → Security Center → Just-in-time VM access\n2. Select the VM you want to access\n3. Click 'Request access' for RDP (3389) or SSH (22)\n4. Access will be granted for 8 hours\n5. All VMs auto-shutdown at 6 PM daily"
  description = "Instructions for accessing VMs using JIT access"
}

output "cost_info" {
  value = "💰 Total monthly cost: ~$25-40 (no public IPs, no VPN Gateway, no Bastion)\n🔒 Security: JIT access via Azure Security Center (free)\n⏰ Auto-shutdown: All VMs shut down at 6 PM daily"
  description = "Cost and security information"
}
