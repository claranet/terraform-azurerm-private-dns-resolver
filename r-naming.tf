data "azurecaf_name" "private_dns_resolver" {
  resource_type = "azurerm_private_dns_resolver"

  name     = var.stack
  use_slug = var.use_caf_naming
  prefixes = var.name_prefix == "" ? null : [local.name_prefix]
  suffixes = compact([var.client_name, var.location_short, var.environment, local.name_suffix, var.use_caf_naming ? "" : "dnspr"])
}

data "azurecaf_name" "inbound_endpoints" {
  for_each = local.inbound_endpoints

  resource_type = "azurerm_private_dns_resolver_inbound_endpoint"

  name     = var.stack
  use_slug = var.use_caf_naming
  prefixes = var.name_prefix == "" ? null : [local.name_prefix]
  suffixes = compact([var.client_name, var.location_short, var.environment, local.name_suffix, trimsuffix(each.key, "-inbe"), var.use_caf_naming ? "" : "dnsprie"])
}

data "azurecaf_name" "outbound_endpoints" {
  for_each = local.outbound_endpoints

  resource_type = "azurerm_private_dns_resolver_outbound_endpoint"

  name     = var.stack
  use_slug = var.use_caf_naming
  prefixes = var.name_prefix == "" ? null : [local.name_prefix]
  suffixes = compact([var.client_name, var.location_short, var.environment, local.name_suffix, trimsuffix(each.key, "-outbe"), var.use_caf_naming ? "" : "dnsproe"])
}

data "azurecaf_name" "dns_forwarding_rulesets" {
  for_each = local.dns_forwarding_rulesets

  resource_type = "azurerm_private_dns_resolver_dns_forwarding_ruleset"

  name     = var.stack
  use_slug = var.use_caf_naming
  prefixes = var.name_prefix == "" ? null : [local.name_prefix]
  suffixes = compact([var.client_name, var.location_short, var.environment, local.name_suffix, each.key, var.use_caf_naming ? "" : "dnsfwrs"])
}

data "azurecaf_name" "forwarding_rules" {
  for_each = local.forwarding_rules

  resource_type = "azurerm_private_dns_resolver_forwarding_rule"

  name     = var.stack
  use_slug = var.use_caf_naming
  prefixes = var.name_prefix == "" ? null : [local.name_prefix]
  suffixes = compact([var.client_name, var.location_short, var.environment, local.name_suffix, each.key, var.use_caf_naming ? "" : "dnsfwr"])
}
