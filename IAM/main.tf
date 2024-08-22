provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  count      = length(var.compartments)
  name       = var.compartments[count.index].name
  location   = var.compartments[count.index].location
  tags = {
    description = var.compartments[count.index].description
  }
}

resource "azuread_group" "example" {
  for_each     = { for group in var.group_config : group.name => group }
  display_name = each.value.name
  description  = each.value.description
  mail_enabled     = false
  security_enabled = true
}

locals {
  group_members = flatten([
    for group in var.group_config : [
      for member in group.members : {
        group_name      = group.name
        group_object_id = azuread_group.example[group.name].object_id
        member_object_id = member
      }
    ]
  ])
}

resource "azuread_group_member" "example" {
  for_each        = { for gm in local.group_members : "${gm.group_name}-${gm.member_object_id}" => gm }
  group_object_id = each.value.group_object_id
  member_object_id = each.value.member_object_id
}

