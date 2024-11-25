resource "azurerm_private_dns_resolver" "main" {
  name     = local.name
  location = var.location

  resource_group_name = var.resource_group_name

  virtual_network_id = local.virtual_network_id

  tags = merge(local.default_tags, var.extra_tags)
}

moved {
  from = azurerm_private_dns_resolver.private_dns_resolver
  to   = azurerm_private_dns_resolver.main
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "main" {
  for_each = local.inbound_endpoints

  name     = coalesce(each.value.custom_name, data.azurecaf_name.inbound_endpoints[each.key].result)
  location = azurerm_private_dns_resolver.main.location

  private_dns_resolver_id = azurerm_private_dns_resolver.main.id

  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = module.subnets[each.key].id
  }

  tags = merge(local.default_tags, var.extra_tags)
}

moved {
  from = azurerm_private_dns_resolver_inbound_endpoint.inbound_endpoints
  to   = azurerm_private_dns_resolver_inbound_endpoint.main
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "main" {
  for_each = local.outbound_endpoints

  name     = coalesce(each.value.custom_name, data.azurecaf_name.outbound_endpoints[each.key].result)
  location = azurerm_private_dns_resolver.main.location

  private_dns_resolver_id = azurerm_private_dns_resolver.main.id
  subnet_id               = module.subnets[each.key].id

  tags = merge(local.default_tags, var.extra_tags)
}

moved {
  from = azurerm_private_dns_resolver_outbound_endpoint.outbound_endpoints
  to   = azurerm_private_dns_resolver_outbound_endpoint.main
}

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "main" {
  for_each = local.dns_forwarding_rulesets

  name     = coalesce(each.value.custom_name, data.azurecaf_name.dns_forwarding_rulesets[each.key].result)
  location = azurerm_private_dns_resolver.main.location

  resource_group_name = var.resource_group_name

  private_dns_resolver_outbound_endpoint_ids = [
    for endpoint in each.value.target_outbound_endpoints : length(regexall(
      "^\\/(subscriptions)\\/([a-z0-9\\-]+)\\/(resourceGroups)\\/([A-Za-z0-9\\-]+)\\/(providers)\\/(Microsoft.Network)\\/(dnsResolvers)\\/([A-Za-z0-9\\-]+)\\/(outboundEndpoints)\\/([A-Za-z0-9\\-]+)$", endpoint
    )) == 1 ? endpoint : azurerm_private_dns_resolver_outbound_endpoint.main[format("%s-%s", endpoint, "outbe")].id
  ]

  tags = merge(local.default_tags, var.extra_tags)
}

moved {
  from = azurerm_private_dns_resolver_dns_forwarding_ruleset.dns_forwarding_rulesets
  to   = azurerm_private_dns_resolver_dns_forwarding_ruleset.main
}

resource "azurerm_private_dns_resolver_forwarding_rule" "main" {
  for_each = local.forwarding_rules

  name = coalesce(each.value.custom_name, data.azurecaf_name.forwarding_rules[each.key].result)

  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.main[each.value.ruleset_name].id
  domain_name               = each.value.domain_name
  enabled                   = each.value.enabled

  dynamic "target_dns_servers" {
    for_each = each.value.dns_servers_ips
    iterator = item
    content {
      ip_address = item.value
      port       = 53 # Fixed value
    }
  }
}

moved {
  from = azurerm_private_dns_resolver_forwarding_rule.forwarding_rules
  to   = azurerm_private_dns_resolver_forwarding_rule.main
}

resource "azurerm_private_dns_resolver_virtual_network_link" "main" {
  count = length(local.virtual_network_links_flattened)

  name = local.virtual_network_links_flattened[count.index].name

  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.main[local.virtual_network_links_flattened[count.index].ruleset_name].id
  virtual_network_id        = local.virtual_network_links_flattened[count.index].virtual_network_id
}

moved {
  from = azurerm_private_dns_resolver_virtual_network_link.vnet_links
  to   = azurerm_private_dns_resolver_virtual_network_link.main
}
