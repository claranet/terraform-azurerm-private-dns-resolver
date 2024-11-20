locals {
  inbound_endpoints       = { for endpoint in var.inbound_endpoints : format("%s-%s", endpoint.name, "inbe") => endpoint }
  outbound_endpoints      = { for endpoint in var.outbound_endpoints : format("%s-%s", endpoint.name, "outbe") => endpoint }
  dns_forwarding_rulesets = { for ruleset in var.dns_forwarding_rulesets : ruleset.name => ruleset }
  forwarding_rules        = { for rule in local.forwarding_rules_flattened : rule.name => rule }

  endpoints = merge(local.inbound_endpoints, local.outbound_endpoints)

  vnet_id = one(compact(concat(
    [var.vnet_id],
    module.vnet[*].id,
  )))

  vnet_name = one(compact(concat(
    [element(reverse(split("/", var.vnet_id)), 0)],
    module.vnet[*].name,
  )))

  vnet_links_flattened = flatten([
    for index, ruleset in var.dns_forwarding_rulesets : [
      for id in concat(index == 0 ? [local.vnet_id] : [], ruleset.vnets_ids) : {
        name         = format("%s-link", element(reverse(split("/", id)), 0))
        vnet_id      = id
        ruleset_name = ruleset.name
      }
    ]
  ])

  forwarding_rules_flattened = flatten([
    for ruleset in var.dns_forwarding_rulesets : [
      for rule in ruleset.rules : merge(
        rule,
        {
          name         = format("%s-%s", ruleset.name, rule.name)
          ruleset_name = ruleset.name
        },
      )
    ]
  ])

  subnets_delegation = {
    "Microsoft.Network.dnsResolvers" = [
      {
        name    = "Microsoft.Network/dnsResolvers"
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    ]
  }
}
