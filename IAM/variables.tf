variable "location" {
  description = "The ID of the parent compartment (resource group)"
  type        = string
  default     = null
}
variable "compartments" {
  description = "List of compartments (resource groups)"
  type        = list(object({
    name     = string
    description = string
    location = string
  }))
}

variable "group_config" {
  type = list(object({
    name     = string
    description = string
    members  = list(string)
  }))
}























/*variable "groups" {
  description = "List of Azure AD groups"
  type        = list(object({
    name        = string
    description = string
    location = string
    user_ids    = list(string)
  }))
}*/


/*variable "compartment_id" {
  description = "The ID of the parent compartment (resource group)"
  type        = string
  default     = null
}*/

/*variable "parent_compartment_name" {
  description = "The name of the parent compartment (resource group)"
  type        = string
}*/




