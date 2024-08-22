
output "vnet_ids" {
  description = "IDs des réseaux virtuels déployés"
  value       = { for k, v in azurerm_virtual_network.vnet : k => v.id }
}

output "subnet_ids" {
  description = "IDs des sous-réseaux déployés"
  value       = { for k, v in azurerm_subnet.subnet : k => v.id }
}

output "vpn_gateway_public_ip" {
  description = "Adresse IP publique de la passerelle VPN"
  value       = azurerm_public_ip.vpn_public_ip.ip_address
}
