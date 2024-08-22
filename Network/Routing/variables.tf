variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Location of the resource group"
  type        = string
}

variable "peerings" {
  description = "A list of VNet peerings to create"
  type = list(object({
    hub = string
    spoke = string
  }))
}

variable "route_tables" {
  description = "La liste des tables de routage Azure avec les règles de routage."
  type        = map(object({
    routes = list(object({
      name                     = string
      address_prefix           = string
      next_hop_type            = string
    }))
  }))
}

variable "route_table_associations" {
  description = "A list of VNet peerings to create"
  type = list(object({
    subnet = string
    route_table = string
  }))
}



























