provider "azurerm" {
  features {}
}

#-------------------------------------------------------------------NSG----------------------------------------------------------------


resource "azurerm_network_security_group" "nsg" {
  for_each            = var.network_security_groups
  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "security_rule" {
    for_each = each.value.security_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }

  /*tags = {
    environment = var.environment
  }*/
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  for_each       = { for assoc in var.subnet_nsg_associations : "${assoc.subnet}-${assoc.nsg}" => assoc }
  subnet_id      = data.terraform_remote_state.vnets.outputs.subnet_ids[each.value.subnet]
  network_security_group_id = azurerm_network_security_group.nsg[each.value.nsg].id
}

#-----------------------------------------------------------------Retrieved Data-------------------------------------------------------