import ipaddress

def new_subnet(vnet_prefixe, subnets_prefixes):
    vnet = ipaddress.ip_network(vnet_prefixe)
    subnets_prefixes = [ipaddress.ip_network(sr) for sr in subnets_prefixes]
    available_subnets = []

    used_capacity = sum(sr.num_addresses for sr in subnets_prefixes)

    for prefixe in range(vnet.prefixlen + 1, 28):
        for subnet in vnet.subnets(new_prefix=prefixe):
            if subnet.num_addresses <= vnet.num_addresses - used_capacity:
                if all(not subnet.overlaps(sr) for sr in subnets_prefixes):
                    available_subnets.append(subnet)

    if available_subnets:
        return available_subnets[-1]
    else:
        return False

#---------------------------------Test----------------------------------

if __name__ == "__main__":
    vnet_prefixe = '10.1.0.0/20'
    subnets_prefixes = ['10.1.0.0/26', '10.1.0.64/26']

    result = new_subnet(vnet_prefixe, subnets_prefixes)

    if result:
        print(f"Prefixe de sous-réseau trouvé : {result}")
    else:
        print("Aucun préfixe de sous-réseau disponible.")
#-----------------------------------------------------------------------



def subnetting(base_network_str, num_subnets):
    base_network = ipaddress.ip_network(base_network_str)

    mask_length = base_network.prefixlen + num_subnets.bit_length() - 1

    if mask_length > 32:
        raise ValueError("Masque de sous-réseau trop long pour IPv4")

    subnets = list(base_network.subnets(new_prefix=mask_length))

    while len(subnets) < num_subnets:
        mask_length += 1
        subnets = list(base_network.subnets(new_prefix=mask_length))

    subnet_prefixes = [str(subnet) for subnet in subnets]

    return subnet_prefixes[:num_subnets]


#---------------------------------Test----------------------------------

if __name__ == "__main__":
    base_network_str = "192.168.0.0/24"
    num_subnets = 3

    subnet_prefixes = subnetting(base_network_str, num_subnets)
    print(subnet_prefixes)
