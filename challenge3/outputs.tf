output "public_ip" {
  description = "Public IP address of the instance"
  value       = azurerm_public_ip.vm.ip_address
}

output "instance_id" {
  description = "ID of the azure virtual machine"
  value       = azurerm_linux_virtual_machine.web.id
}

output "ssh_user_at" {
  description = "Quick SSH hint (replace <private-key-path> if needed)"
  value       = "ssh azureuser@${azurerm_public_ip.vm.ip_address}"
}
