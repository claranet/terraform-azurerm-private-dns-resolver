locals {
  inbound_endpoints_output = {
    for endpoint_name in keys(local.inbound_endpoints) : endpoint_name => {
      id                 = azurerm_private_dns_resolver_inbound_endpoint.main[endpoint_name].id
      subnet_id          = module.subnets[endpoint_name].id
      subnet_name        = module.subnets[endpoint_name].name
      private_ip_address = azurerm_private_dns_resolver_inbound_endpoint.main[endpoint_name].ip_configurations[0].private_ip_address
    }
  }

  outbound_endpoints_output = {
    for endpoint_name in keys(local.outbound_endpoints) : endpoint_name => {
      id          = azurerm_private_dns_resolver_outbound_endpoint.main[endpoint_name].id
      subnet_id   = module.subnets[endpoint_name].id
      subnet_name = module.subnets[endpoint_name].name
    }
  }

  dns_forwarding_rulesets_output = {
    for ruleset_name in keys(local.dns_forwarding_rulesets) : ruleset_name => {
      id             = azurerm_private_dns_resolver_dns_forwarding_ruleset.main[ruleset_name].id
      rules_ids      = [for rule in local.forwarding_rules : azurerm_private_dns_resolver_forwarding_rule.main[rule.name].id if rule.ruleset_name == ruleset_name]
      vnet_links_ids = [for index, link in local.vnet_links_flattened : azurerm_private_dns_resolver_virtual_network_link.main[index].id if link.ruleset_name == ruleset_name]
    }
  }
}
