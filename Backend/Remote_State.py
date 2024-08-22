import os
import json
import random
import string
from openpyxl import load_workbook
from jinja2 import Template

parent_dir = os.path.dirname(os.path.abspath(__file__))
tfstate_file_path = os.path.join(parent_dir, 'network-tfstate_terraform.tfstate')
tfstate_iam_path = os.path.join(parent_dir, 'terraform.tfstate')
output_file_path = os.path.join(parent_dir, '..', 'Network', 'VNets', 'main.tf')
output_file_path_routing = os.path.join(parent_dir, '..', 'Network', 'Routing', 'main.tf')
output_file_path_security = os.path.join(parent_dir, '..', 'Network', 'Security', 'main.tf')
storage_file_path = os.path.join(parent_dir, '..', 'Network', 'Storage', 'main.tf')
excel_file_path = os.path.join(parent_dir, 'OCI.xlsx')
wb = load_workbook(excel_file_path, data_only=True)

with open(tfstate_file_path, "r") as file:
    tfstate_data = json.load(file)
    
with open(tfstate_iam_path, "r") as file:
    tfstate_iam_data = json.load(file)
    
#-------------------------------------------------------------------------------------------------------------

def generate_random_name(prefix, length=8):
    return prefix + ''.join(random.choices(string.ascii_lowercase + string.digits, k=length))

#-------------------------------------------------------------------------------------------------------------

compartment_dict = {
    compartment["id"]: compartment["name"]
    for compartment in tfstate_iam_data["outputs"]["compartments"]["value"].values()
}

def network_rg(tfstate_data):
    rg_ids = set()
    
    for resource in tfstate_data.get("resources", []):
        if resource.get("type") == "oci_core_vcn" and resource.get("mode") == "managed":
            for instance in resource.get("instances", []):
                attributes = instance.get("attributes", {})
                compartment_id = attributes.get("compartment_id", "Unknown ID")
                rg_ids.add(compartment_id)
    
    return rg_ids

network_rg_ids = network_rg(tfstate_data)

def resource_group(compartment_dict, network_rg_ids):
    for rg_id, rg_name in compartment_dict.items():
        if rg_id in network_rg_ids:
            return rg_name

resource_group = resource_group(compartment_dict, network_rg_ids)

#-------------------------------------------------------------------------------------------------------------

region_map = {
    "eu-paris-1": "eastus"
}

def get_region(tfstate_iam_data, region_map):
    region_ = [
        instance["attributes"]["reporting_region"]
        for resource in tfstate_iam_data["resources"]
        if "type" in resource and resource["type"] == "oci_cloud_guard_cloud_guard_configuration"
        and "mode" in resource and resource["mode"] == "managed"
        for instance in resource.get("instances", [])
        if "attributes" in instance and "reporting_region" in instance["attributes"]
    ]

    region = ', '.join(region_map.get(r, r) for r in region_)
    
    return region

region = get_region(tfstate_iam_data, region_map)

#-------------------------------------------------------------------------------------------------------------

storage_account_name = generate_random_name("remotestate")

template_str = """
provider "azurerm" {
  features {}
}

resource "azurerm_storage_account" "sa" {
  name                     = "{{ storage_account_name }}"
  resource_group_name      = "{{ resource_group }}"
  location                 = "{{ region }}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "container" {
  name                  = "terraform-state"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"

  depends_on = [azurerm_storage_account.sa]
}
"""

template_bck = """
terraform {
  backend "azurerm" {
    resource_group_name  = "{{ resource_group }}"
    storage_account_name = "{{ storage_account_name }}"
    container_name       = "terraform-state"
    key                  = "VNets/terraform.tfstate"
  }
}
"""

template_data = """
data "terraform_remote_state" "vnets" {
  backend = "azurerm"

  config = {
    resource_group_name   = var.resource_group_name
    storage_account_name  = "{{ storage_account_name }}"
    container_name        = "terraform-state"
    key                   = "VNets/terraform.tfstate"
  }
}
"""

template_1 = Template(template_str)
template_2 = Template(template_bck)
template_3 = Template(template_data)

#--------------------------------------------------------------------------------------------------------------

new_resources = template_2.render(
    storage_account_name=storage_account_name,
    resource_group=resource_group,
    region=region
)

existing_content = ""
if os.path.exists(output_file_path):
    with open(output_file_path, "r") as f:
        existing_content = f.read()

updated_content = existing_content + "\n" + new_resources

with open(output_file_path, "w") as f:
    f.write(updated_content)

#--------------------------------------------------------------------------------------------------------------

new_resources_routing_security = template_3.render(
    storage_account_name=storage_account_name
)


existing_content_routing = ""
if os.path.exists(output_file_path_routing):
    with open(output_file_path_routing, "r") as f:
        existing_content_routing = f.read()

updated_content_routing = existing_content_routing + "\n" + new_resources_routing_security

with open(output_file_path_routing, "w") as f:
    f.write(updated_content_routing)

existing_content_security = ""
if os.path.exists(output_file_path_security):
    with open(output_file_path_security, "r") as f:
        existing_content_security = f.read()

updated_content_security = existing_content_security + "\n" + new_resources_routing_security

with open(output_file_path_security, "w") as f:
    f.write(updated_content_security)

print("Les nouvelles ressources ont été ajoutées au fichier main.tf avec succès.")

#--------------------------------------------------------------------------------------------------------------

new_storage_content = template_1.render(
    resource_group=resource_group,
    storage_account_name=storage_account_name,
    region=region
)

with open(storage_file_path, "w") as f:
    f.write(new_storage_content)

print("Le contenu pour le fichier storage a été généré avec succès.")
