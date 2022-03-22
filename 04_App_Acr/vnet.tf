resource "azurerm_resource_group" "RG" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "VNET" {
  name                = var.vnet_name
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  address_space       = var.vnet_address_space

  dynamic "subnet" {
    for_each = var.vnet_subnets
    content {
      name           = subnet.value.name
      address_prefix = subnet.value.address_prefix
    }
  }

}

resource "azurerm_subnet" "SUBNETS" {
  count                = length(var.subnets_delegated)
  resource_group_name  = azurerm_resource_group.RG.name
  name                 = var.subnets_delegated[count.index].subnet_name
  virtual_network_name = azurerm_virtual_network.VNET.name
  address_prefixes     = var.subnets_delegated[count.index].subnet_address_prefixes
  service_endpoints    = var.subnets_delegated[count.index].subnet_service_endpoints

  delegation {
    name = var.subnets_delegated[count.index].subnet_delegation_name

    service_delegation {
      name    = var.subnets_delegated[count.index].subnet_service_name
      actions = var.subnets_delegated[count.index].subnet_service_acions
    }
  }
}

resource "azurerm_network_security_group" "NSG" {
  count               = length(azurerm_virtual_network.VNET.subnet.*.id)
  name                = "${azurerm_virtual_network.VNET.subnet[count.index].name}-nsg"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
}

resource "azurerm_subnet_network_security_group_association" "nsg_subnet_assoc" {
  count                     = length(azurerm_virtual_network.VNET.subnet.*.id)
  subnet_id                 = azurerm_virtual_network.VNET.subnet[count.index].id
  network_security_group_id = azurerm_network_security_group.NSG[count.index].id
}