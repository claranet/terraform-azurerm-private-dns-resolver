resource "azurerm_private_dns_resolver" "private_dns_resolver" {
  name     = local.private_dns_resolver_name
  location = var.location

  resource_group_name = var.resource_group_name

  virtual_network_id = local.vnet_id

  tags = merge(local.default_tags, var.extra_tags)
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "inbound_endpoints" {
  for_each = local.inbound_endpoints

  name     = coalesce(each.value.custom_name, data.azurecaf_name.inbound_endpoints[each.key].result)
  location = azurerm_private_dns_resolver.private_dns_resolver.location

  private_dns_resolver_id = azurerm_private_dns_resolver.private_dns_resolver.id

  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = module.subnets[each.key].subnet_id
  }

  tags = merge(local.default_tags, var.extra_tags)
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "outbound_endpoints" {
  for_each = local.outbound_endpoints

  name     = coalesce(each.value.custom_name, data.azurecaf_name.outbound_endpoints[each.key].result)
  location = azurerm_private_dns_resolver.private_dns_resolver.location

  private_dns_resolver_id = azurerm_private_dns_resolver.private_dns_resolver.id
  subnet_id               = module.subnets[each.key].subnet_id

  tags = merge(local.default_tags, var.extra_tags)
}

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "dns_forwarding_rulesets" {
  for_each = local.dns_forwarding_rulesets

  name     = coalesce(each.value.custom_name, data.azurecaf_name.dns_forwarding_rulesets[each.key].result)
  location = azurerm_private_dns_resolver.private_dns_resolver.location

  resource_group_name = var.resource_group_name

  private_dns_resolver_outbound_endpoint_ids = [
    for endpoint in each.value.target_outbound_endpoints : length(regexall(
      "^\\/(subscriptions)\\/([a-z0-9\\-]+)\\/(resourceGroups)\\/([A-Za-z0-9\\-]+)\\/(providers)\\/(Microsoft.Network)\\/(dnsResolvers)\\/([A-Za-z0-9\\-]+)\\/(outboundEndpoints)\\/([A-Za-z0-9\\-]+)$", endpoint
    )) == 1 ? endpoint : azurerm_private_dns_resolver_outbound_endpoint.outbound_endpoints[format("%s-%s", endpoint, "outbe")].id
  ]

  tags = merge(local.default_tags, var.extra_tags)
}

resource "azurerm_private_dns_resolver_forwarding_rule" "forwarding_rules" {
  for_each = local.forwarding_rules

  name = coalesce(each.value.custom_name, data.azurecaf_name.forwarding_rules[each.key].result)

  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.dns_forwarding_rulesets[each.value.ruleset_name].id
  domain_name               = each.value.domain_name
  enabled                   = each.value.enabled

  dynamic "target_dns_servers" {
    for_each = each.value.dns_servers_ips
    iterator = elem
    content {
      ip_address = elem.value
      port       = 53 # Fixed value
    }
  }
}

resource "azurerm_private_dns_resolver_virtual_network_link" "vnet_links" {
  count = length(local.vnet_links_flattened)

  name = local.vnet_links_flattened[count.index].name

  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.dns_forwarding_rulesets[local.vnet_links_flattened[count.index].ruleset_name].id
  virtual_network_id        = local.vnet_links_flattened[count.index].vnet_id
}
