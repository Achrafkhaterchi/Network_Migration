variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Location of the resource group"
  type        = string
}

variable "vnets" {
  description = "Map of VNETs with their address spaces"
  type        = map(object({
    address_space = list(string)
  }))
}

variable "GatewaySubnet" {
  description = "Configuration for the Gateway Subnet"
  type = object({
    vnet_name        = string
    address_prefixes = list(string)
  })
}

variable "subnets" {
  description = "Map of subnets with their address prefixes and associated VNET"
  type        = map(object({
    vnet_name       = string
    address_prefixes = list(string)
  }))
}






