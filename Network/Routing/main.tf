provider "azurerm" {
  features {}
}

#----------------------------------------------------------------VNet Peering----------------------------------------------------------

resource "azurerm_virtual_network_peering" "vnet_peering_to_hub" {
  for_each = {
    for peering in var.peerings :
    "${peering.spoke}-to-${peering.hub}" => peering
  }

  name                          = "${each.value.spoke}-to-${each.value.hub}-peering"
  resource_group_name           = var.resource_group_name
  virtual_network_name          = each.value.spoke
  remote_virtual_network_id     = data.terraform_remote_state.vnets.outputs.vnet_ids[each.value.hub]
  allow_virtual_network_access  = true
  allow_forwarded_traffic       = true
  allow_gateway_transit         = true
  use_remote_gateways           = true
}

resource "azurerm_virtual_network_peering" "vnet_peering_to_spokes" {
  for_each = {
    for peering in var.peerings :
    "${peering.hub}-to-${peering.spoke}" => peering
  }

  name                          = "${each.value.hub}-to-${each.value.spoke}-peering"
  resource_group_name           = var.resource_group_name
  virtual_network_name          = each.value.hub
  remote_virtual_network_id     = data.terraform_remote_state.vnets.outputs.vnet_ids[each.value.spoke]
  allow_virtual_network_access  = true
  allow_forwarded_traffic       = true
  allow_gateway_transit         = true
  use_remote_gateways           = false
}

#-----------------------------------------------------------------Route Tables---------------------------------------------------------

resource "azurerm_route_table" "route_table" {
  for_each            = var.route_tables
  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name
}

locals {
  all_routes = flatten([
    for table_key, table_value in var.route_tables : [
      for route in table_value.routes : {
        table_key = table_key
        route     = route
      }
    ]
  ])
}

resource "azurerm_route" "route" {
  for_each = {
    for idx, route in local.all_routes : "${route.table_key}-${route.route.name}" => route
  }

  resource_group_name = var.resource_group_name
  route_table_name    = azurerm_route_table.route_table[each.value.table_key].name
  name                = each.value.route.name
  address_prefix      = each.value.route.address_prefix
  next_hop_type       = each.value.route.next_hop_type
}

resource "azurerm_subnet_route_table_association" "route_association" {
  for_each       = { for assoc in var.route_table_associations : "${assoc.subnet}-${assoc.route_table}" => assoc }
  subnet_id      = data.terraform_remote_state.vnets.outputs.subnet_ids[each.value.subnet]
  route_table_id = azurerm_route_table.route_table[each.value.route_table].id
}

#-----------------------------------------------------------------Retrieved Data-------------------------------------------------------