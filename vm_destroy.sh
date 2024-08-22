#!/bin/bash

resource_group="LZdemo-network-cmp"

vm_names=$(az vm list --resource-group "$resource_group" --query "[].name" --output tsv | tr -d '\r')

IFS=$'\n' read -r -d '' -a vms <<< "$vm_names"

echo "Les VMs à supprimer :"
for vm in "${vms[@]}"; do
    echo "$vm"
done


delete_vm() {
    local vm_name=$1
    echo "Suppression de la VM : $vm_name"

    nic_id=$(az vm show --resource-group "$resource_group" --name "$vm_name" --query "networkProfile.networkInterfaces[0].id" --output tsv)

    os_disk_id=$(az vm show --resource-group "$resource_group" --name "$vm_name" --query "storageProfile.osDisk.managedDisk.id" --output tsv)

    public_ip_id=$(az network nic show --ids "$nic_id" --query "ipConfigurations[0].publicIpAddress.id" --output tsv)

    nsg_id=$(az network nic show --ids "$nic_id" --query "networkSecurityGroup.id" --output tsv)

    az vm delete --resource-group "$resource_group" --name "$vm_name" --yes --no-wait
    if [ $? -ne 0 ]; then
        echo "Erreur lors de la suppression de la VM : $vm_name"
    else
        echo "VM supprimée avec succès : $vm_name"
    fi

    echo "Attente de la suppression complète de la VM : $vm_name"
    az vm wait --deleted --resource-group "$resource_group" --name "$vm_name"

    if [ -n "$nic_id" ]; then
        az network nic delete --ids "$nic_id" --no-wait
        if [ $? -ne 0 ]; then
            echo "Erreur lors de la suppression de l'interface réseau : $nic_id"
        else
            echo "Interface réseau supprimée avec succès : $nic_id"
        fi
    fi

    if [ -n "$os_disk_id" ]; then
        az disk delete --ids "$os_disk_id" --yes --no-wait
        if [ $? -ne 0 ]; then
            echo "Erreur lors de la suppression du disque : $os_disk_id"
        else
            echo "Disque supprimé avec succès : $os_disk_id"
        fi
    fi

    if [ -n "$public_ip_id" ]; then
        az network public-ip delete --ids "$public_ip_id" --no-wait
        if [ $? -ne 0 ]; then
            echo "Erreur lors de la suppression de l'adresse IP publique : $public_ip_id"
        else
            echo "Adresse IP publique supprimée avec succès : $public_ip_id"
        fi
    fi

    if [ -n "$nsg_id" ]; then
        az network nsg delete --ids "$nsg_id" --no-wait
        if [ $? -ne 0 ]; then
            echo "Erreur lors de la suppression du groupe de sécurité réseau : $nsg_id"
        else
            echo "Groupe de sécurité réseau supprimé avec succès : $nsg_id"
        fi
    fi
}

for vm in "${vms[@]}"; do
    delete_vm "$vm"
done
