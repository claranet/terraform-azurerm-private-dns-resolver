module "vnet" {
  source  = "claranet/vnet/azurerm"
  version = "~> 8.0.0"

  count = var.virtual_network_id == "" ? 1 : 0

  location       = var.location
  location_short = var.location_short
  client_name    = var.client_name
  environment    = var.environment
  stack          = var.stack

  resource_group_name = var.resource_group_name

  name_prefix = local.name_prefix
  name_suffix = local.name_suffix
  custom_name = var.virtual_network_custom_name

  cidrs = [var.virtual_network_cidr]

  default_tags_enabled = var.default_tags_enabled

  extra_tags = var.extra_tags
}

module "subnets" {
  source  = "claranet/subnet/azurerm"
  version = "~> 8.0.0"

  for_each = local.endpoints

  location_short = var.location_short
  client_name    = var.client_name
  environment    = var.environment
  stack          = var.stack

  resource_group_name = coalesce(local.vnet_rg, var.resource_group_name)

  name_prefix = local.name_prefix
  name_suffix = each.value.subnet_custom_name != "" ? local.name_suffix != "" ? format("%s-%s", local.name_suffix, each.key) : each.key : ""
  custom_name = each.value.subnet_custom_name

  virtual_network_name = local.virtual_network_name
  delegations          = local.subnets_delegation

  private_link_service_enabled  = true
  private_link_endpoint_enabled = false

  cidrs = [each.value.cidr]

  default_outbound_access_enabled = each.value.default_outbound_access_enabled
}
