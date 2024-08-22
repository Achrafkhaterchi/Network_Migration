#!/bin/bash

RESOURCE_GROUP="LZdemo-network-cmp"
VM_SIZE="Standard_B1s"
VM_IMAGE="Ubuntu2204"
USERNAME="azureuser"
PASSWORD="Azety@97141163"
VM_COUNT=1

function print_message() {
  local MESSAGE=$1
  local COLOR=$2
  case $COLOR in
    "green")
      echo -e "\e[32m$MESSAGE\e[0m"
      ;;
    "red")
      echo -e "\e[31m$MESSAGE\e[0m"
      ;;
    *)
      echo "$MESSAGE"
      ;;
  esac
}

VNETS=$(az network vnet list --resource-group $RESOURCE_GROUP --query "[].name" -o tsv)
echo "VNets récupérés :"
echo "$VNETS"

for VNET in $VNETS; do
  VNET=$(echo $VNET | tr -d '\r')
  echo "Traitement du VNet : $VNET"

  SUBNETS=$(az network vnet subnet list --resource-group $RESOURCE_GROUP --vnet-name $VNET --query "[?name!='GatewaySubnet'].{name:name, addressPrefix:addressPrefix}" -o tsv)
  echo "Sous-réseaux trouvés dans le VNet $VNET :"
  echo "$SUBNETS"

  if [ -z "$SUBNETS" ]; then
    echo "Aucun sous-réseau valide trouvé dans le VNet $VNET."
    continue
  fi

  SUBNET_NAME=$(echo "$SUBNETS" | head -n 1 | awk '{print $1}')
  echo "Utilisation du sous-réseau $SUBNET_NAME dans le VNet $VNET."

  for i in $(seq 1 $VM_COUNT); do
    VM_NAME="${VNET}-vm${i}"
    VM_NAME=$(echo $VM_NAME | tr -d '\r')

    az vm create \
      --resource-group $RESOURCE_GROUP \
      --name $VM_NAME \
      --vnet-name $VNET \
      --subnet $SUBNET_NAME \
      --image $VM_IMAGE \
      --size $VM_SIZE \
      --admin-username $USERNAME \
      --admin-password $PASSWORD \
      --no-wait
  done
done

echo "Attente de la création des VM..."

VM_LIST=$(az vm list --resource-group $RESOURCE_GROUP --query "[].{Name:name, ID:id}" -o table)
echo "Liste des VM créées :"
echo "$VM_LIST"

VM_IDS=$(az vm list --resource-group $RESOURCE_GROUP --query "[].id" -o tsv)
echo "VM IDs: $VM_IDS"

if [ -z "$VM_IDS" ]; then
  echo "Aucun ID de VM trouvé. Veuillez vérifier la création des VM."
  exit 1
fi

az vm wait --created --ids $VM_IDS --timeout 120

VM_INFO=$(az vm list-ip-addresses --resource-group $RESOURCE_GROUP --query "[].{Name:virtualMachine.name, PrivateIP:virtualMachine.network.privateIpAddresses[0]}" -o tsv)
echo "VM Info: $VM_INFO"

IFS=$'\n' read -d '' -r -a VM_ARRAY <<< "$VM_INFO"

for ((i=0; i<${#VM_ARRAY[@]}; i++)); do
  SRC_VM_INFO=${VM_ARRAY[i]}
  SRC_VM_NAME=$(echo "$SRC_VM_INFO" | awk '{print $1}')
  SRC_IP=$(echo "$SRC_VM_INFO" | awk '{print $2}')

  for ((j=0; j<${#VM_ARRAY[@]}; j++)); do
    if [ $i -ne $j ]; then
      DST_VM_INFO=${VM_ARRAY[j]}
      DST_VM_NAME=$(echo "$DST_VM_INFO" | awk '{print $1}')
      DST_IP=$(echo "$DST_VM_INFO" | awk '{print $2}')

      echo "Tester le ping de $SRC_IP vers $DST_IP"
      PING_RESULT=$(az vm run-command invoke --command-id RunShellScript --name $SRC_VM_NAME --resource-group $RESOURCE_GROUP --scripts "ping -c 4 $DST_IP" --query "value[0].message" -o tsv)
      echo "$PING_RESULT"
      if echo "$PING_RESULT" | grep -q " 0% packet loss"; then
        print_message "Le ping de $SRC_IP vers $DST_IP est réussi. La VM $SRC_VM_NAME peut communiquer avec la VM $DST_VM_NAME." "green"
      else
        print_message "Le ping de $SRC_IP vers $DST_IP a échoué. La VM $SRC_VM_NAME ne peut pas communiquer avec la VM $DST_VM_NAME." "red"
      fi
    fi
  done
done
