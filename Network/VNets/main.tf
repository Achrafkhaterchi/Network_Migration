provider "azurerm" {
  features {}
}


#------------------------------------------------------------------VNets---------------------------------------------------------------

resource "azurerm_virtual_network" "vnet" {
  for_each            = var.vnets
  name                = each.key
  address_space       = each.value.address_space
  location            = var.location
  resource_group_name = var.resource_group_name

  /*tags = {
    environment = var.environment
  }*/
}

#-----------------------------------------------------------------Subnets--------------------------------------------------------------

resource "azurerm_subnet" "subnet" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet[each.value.vnet_name].name
  address_prefixes     = each.value.address_prefixes
}

#-------------------------------------------------------------------VPN----------------------------------------------------------------

locals {
  gateway_subnet_vnet = azurerm_virtual_network.vnet[var.GatewaySubnet.vnet_name]
}

resource "azurerm_subnet" "hub_gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = local.gateway_subnet_vnet.name
  address_prefixes     = var.GatewaySubnet.address_prefixes
  depends_on = [
    local.gateway_subnet_vnet
  ]
}


resource "azurerm_public_ip" "vpn_public_ip" {
  name                = "vpn-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_virtual_network_gateway" "vpn_gateway" {
  name                = "vpn-gateway"
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"

  ip_configuration {
    name                          = "vpn-gateway-ip-configuration"
    public_ip_address_id          = azurerm_public_ip.vpn_public_ip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.hub_gateway_subnet.id
  }
}


#--------------------------------------------------------------Remote_State------------------------------------------------------------