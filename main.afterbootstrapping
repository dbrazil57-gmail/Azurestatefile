
resource "azurerm_resource_group" "network" {
  name     = local.resource_group_name
  location = local.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "public_vnet" {
  name                = "public-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  tags                = local.tags
}

resource "azurerm_virtual_network" "private_vnet" {
  name                = "private-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  tags                = local.tags
}

resource "azurerm_subnet" "public" {
  name                 = "public-subnet"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.public_vnet.name
  address_prefixes     = [local.public_subnet_cidr]
}

resource "azurerm_subnet" "private" {
  name                 = "private-subnet"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.private_vnet.name
  address_prefixes     = [local.private_subnet_cidr]
}

resource "azurerm_public_ip" "nat_ip" {
  name                = "nat-ip"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat" {
  name                = "nat-gateway"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat_ip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.nat_ip.id
}

resource "azurerm_subnet_nat_gateway_association" "private_nat" {
  subnet_id      = azurerm_subnet.private.id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}

resource "azurerm_route_table" "public_rt" {
  name                = "public-route-table"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name

  route {
    name           = "internet-route"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }

  tags = local.tags
}

resource "azurerm_subnet_route_table_association" "public_rt_assoc" {
  subnet_id      = azurerm_subnet.public.id
  route_table_id = azurerm_route_table.public_rt.id
}

resource "azurerm_route_table" "private_rt" {
  name                = "private-route-table"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  tags                = local.tags
}

resource "azurerm_subnet_route_table_association" "private_rt_assoc" {
  subnet_id      = azurerm_subnet.private.id
  route_table_id = azurerm_route_table.private_rt.id
}

resource "azurerm_virtual_network_peering" "public_to_private" {
  name                      = "public-to-private"
  resource_group_name       = azurerm_resource_group.network.name
  virtual_network_name      = azurerm_virtual_network.public_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.private_vnet.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}

resource "azurerm_virtual_network_peering" "private_to_public" {
  name                      = "private-to-public"
  resource_group_name       = azurerm_resource_group.network.name
  virtual_network_name      = azurerm_virtual_network.private_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.public_vnet.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.public_vnet.name
  address_prefixes     = [local.bastion_subnet_cidr]
}

resource "azurerm_public_ip" "bastion_ip" {
  name                = "bastion-public-ip"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                = "bastion-host"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  sku                 = "Basic"

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion_ip.id
  }

  tags = local.tags
}
