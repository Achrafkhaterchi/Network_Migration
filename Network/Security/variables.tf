variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Location of the resource group"
  type        = string
}

variable "network_security_groups" {
  description = "Map of NSGs with their security rules"
  type = map(object({
    security_rules      = list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    }))
  }))
}

variable "subnet_nsg_associations" {
  description = "List of subnet to NSG associations"
  type = list(object({
    subnet = string
    nsg    = string
  }))
}

