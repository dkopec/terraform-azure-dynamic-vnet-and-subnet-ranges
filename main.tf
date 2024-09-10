#region LOCALS

locals {
  name_seperator = "-"
  name_stack     = "core-${var.business_unit_short}-${var.environment}-${var.region}"
  tags = merge(var.tags, {
    "environment"   = var.environment
    "business_unit" = var.business_unit
    "built-with"    = "Terraform"
  })
}

data "external" "vnets" {
  program = ["bash", "scripts/azure-vnets-data-source.sh"]
}

locals {
  last_vnet = data.external.vnets.result.vnet
}

data "external" "new_range" {
  program = ["bash", "scripts/next_cidr_block.sh", local.last_vnet, "21"]
}

locals {
  new_vnet_range = data.external.new_range.result.new_cidr
}

#endregion

#region Resource Group

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_stack}"
  location = var.location

  tags = merge(local.tags, {

  })
}

#endregion

#region VNET

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${local.name_stack}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  address_space       = [local.new_vnet_range]

  tags = merge(local.tags, {

  })

  lifecycle {
    ignore_changes = [address_space, tags]
  }
}

#region Subnets

resource "azurerm_subnet" "private_endpoints" {
  name                                          = "snet-private-endpoint-${local.name_stack}"
  resource_group_name                           = azurerm_resource_group.this.name
  virtual_network_name                          = azurerm_virtual_network.this.name
  address_prefixes                              = [cidrsubnet(local.new_vnet_range, 3, 1)]
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = false
  service_endpoints                             = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.ContainerRegistry", "Microsoft.ServiceBus"]
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [cidrsubnet(local.new_vnet_range, 3, 2)]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.ContainerRegistry", "Microsoft.ServiceBus"]
}

resource "azurerm_subnet" "db" {
  name                 = "snet-psql-${local.name_stack}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [cidrsubnet(local.new_vnet_range, 3, 3)]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.ContainerRegistry", "Microsoft.ServiceBus"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet" "apps" {
  name                 = "snet-apps-${local.name_stack}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [cidrsubnet(local.new_vnet_range, 3, 4)]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.ContainerRegistry", "Microsoft.ServiceBus"]
}

#endregion
#endregion
