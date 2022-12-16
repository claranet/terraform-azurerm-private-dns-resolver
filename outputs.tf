output "private_dns_resolver" {
  description = "Private DNS Resolver outputs."
  value = {
    id      = azurerm_private_dns_resolver.private_dns_resolver.id
    vnet_id = local.vnet_id
  }
}

output "inbound_endpoints" {
  description = "Maps of Private DNS Resolver Inbound Endpoints outputs."
  value = {
    for endpoint_name in keys(local.inbound_endpoints) : endpoint_name => {
      id                 = azurerm_private_dns_resolver_inbound_endpoint.inbound_endpoints[endpoint_name].id
      subnet_id          = module.subnets[endpoint_name].subnet_id
      private_ip_address = azurerm_private_dns_resolver_inbound_endpoint.inbound_endpoints[endpoint_name].ip_configurations[0].private_ip_address
    }
  }
}

output "outbound_endpoints" {
  description = "Maps of Private DNS Resolver Outbound Endpoints outputs."
  value = {
    for endpoint_name in keys(local.outbound_endpoints) : endpoint_name => {
      id        = azurerm_private_dns_resolver_outbound_endpoint.outbound_endpoints[endpoint_name].id
      subnet_id = module.subnets[endpoint_name].subnet_id
    }
  }
}

output "dns_forwarding_rulesets" {
  description = "Maps of Private DNS Resolver DNS Forwarding Rulesets outputs."
  value = {
    for ruleset_name in keys(local.dns_forwarding_rulesets) : ruleset_name => {
      id             = azurerm_private_dns_resolver_dns_forwarding_ruleset.dns_forwarding_rulesets[ruleset_name].id
      rules_ids      = [for rule in local.forwarding_rules : azurerm_private_dns_resolver_forwarding_rule.forwarding_rules[rule.name].id if rule.ruleset_name == ruleset_name]
      vnet_links_ids = [for index, link in local.vnet_links_flattened : azurerm_private_dns_resolver_virtual_network_link.vnet_links[index].id if link.ruleset_name == ruleset_name]
    }
  }
}
