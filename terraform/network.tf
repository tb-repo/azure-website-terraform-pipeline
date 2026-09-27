data "azurerm_resource_group" "lab" {
  name = "tb_rg"
}

resource "azurerm_virtual_network" "lab" {
  name                = "tb_vnet"
  location            = data.azurerm_resource_group.lab.location
  resource_group_name = data.azurerm_resource_group.lab.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    Name    = "tb_vnet"
    purpose = "website-learning-lab"
  }
}

resource "azurerm_subnet" "public" {
  name                 = "tb-snet-public"
  resource_group_name  = data.azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "private" {
  name                            = "tb-snet-private"
  resource_group_name             = data.azurerm_resource_group.lab.name
  virtual_network_name            = azurerm_virtual_network.lab.name
  address_prefixes                = ["10.0.2.0/24"]
  default_outbound_access_enabled = false
}

resource "azurerm_route_table" "public" {
  name                = "tb-rt-public"
  location            = data.azurerm_resource_group.lab.location
  resource_group_name = data.azurerm_resource_group.lab.name

  route {
    name           = "default-internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }

  tags = {
    Name = "tb-rt-public"
  }
}

resource "azurerm_subnet_route_table_association" "public" {
  subnet_id      = azurerm_subnet.public.id
  route_table_id = azurerm_route_table.public.id
}

resource "azurerm_network_security_group" "public" {
  name                = "tb-nsg-public"
  location            = data.azurerm_resource_group.lab.location
  resource_group_name = data.azurerm_resource_group.lab.name

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "tb-nsg-public"
  }
}

resource "azurerm_network_security_group" "private" {
  name                = "tb-nsg-private"
  location            = data.azurerm_resource_group.lab.location
  resource_group_name = data.azurerm_resource_group.lab.name

  tags = {
    Name = "tb-nsg-private"
  }
}

resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public.id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private.id
}

resource "azurerm_public_ip" "web" {
  name                = "tb-pip-web"
  location            = data.azurerm_resource_group.lab.location
  resource_group_name = data.azurerm_resource_group.lab.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Name = "tb-pip-web"
  }
}

resource "azurerm_public_ip" "nat" {
  name                = "tb-pip-nat"
  location            = data.azurerm_resource_group.lab.location
  resource_group_name = data.azurerm_resource_group.lab.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Name = "tb-pip-nat"
  }
}

resource "azurerm_nat_gateway" "private" {
  name                    = "tb-nat-private"
  location                = data.azurerm_resource_group.lab.location
  resource_group_name     = data.azurerm_resource_group.lab.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10

  tags = {
    Name = "tb-nat-private"
  }
}

resource "azurerm_nat_gateway_public_ip_association" "private" {
  nat_gateway_id       = azurerm_nat_gateway.private.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "private" {
  subnet_id      = azurerm_subnet.private.id
  nat_gateway_id = azurerm_nat_gateway.private.id
}