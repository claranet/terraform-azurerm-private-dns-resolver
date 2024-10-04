module "vnet" {
  source  = "claranet/vnet/azurerm"
  version = "7.1.0"

  count = var.vnet_id == "" ? 1 : 0

  client_name    = var.client_name
  location       = var.location
  location_short = var.location_short
  environment    = var.environment
  stack          = var.stack

  resource_group_name = var.resource_group_name

  name_prefix      = local.name_prefix
  name_suffix      = local.name_suffix
  custom_vnet_name = var.custom_vnet_name

  vnet_cidr = [var.vnet_cidr]

  default_tags_enabled = var.default_tags_enabled

  extra_tags = var.extra_tags
}

module "subnets" {
  source  = "claranet/subnet/azurerm"
  version = "7.2.0"

  for_each = local.endpoints

  client_name    = var.client_name
  location_short = var.location_short
  environment    = var.environment
  stack          = var.stack

  resource_group_name = var.resource_group_name

  name_prefix        = local.name_prefix
  name_suffix        = each.value.custom_subnet_name != "" ? local.name_suffix != "" ? format("%s-%s", local.name_suffix, each.key) : each.key : ""
  custom_subnet_name = each.value.custom_subnet_name

  virtual_network_name = local.vnet_name
  subnet_delegation    = local.subnets_delegation

  private_link_service_enabled  = true
  private_link_endpoint_enabled = false

  subnet_cidr_list = [each.value.cidr]
}
