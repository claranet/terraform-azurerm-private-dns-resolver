output "resource" {
  description = "Private DNS Resolver resource object."
  value       = azurerm_private_dns_resolver.main
}

output "resource_inbound_endpoint" {
  description = "Private DNS Resolver inbound endpoint resource object."
  value       = azurerm_private_dns_resolver_inbound_endpoint.main
}

output "resource_outbound_endpoint" {
  description = "Private DNS Resolver outbound endpoint resource object."
  value       = azurerm_private_dns_resolver_outbound_endpoint.main
}

output "resource_dns_forwarding_ruleset" {
  description = "Private DNS Resolver DNS forwarding ruleset resource object."
  value       = azurerm_private_dns_resolver_dns_forwarding_ruleset.main
}

output "resource_forwarding_rule" {
  description = "Private DNS Resolver forwarding rule resource object."
  value       = azurerm_private_dns_resolver_forwarding_rule.main
}

output "resource_virtual_network_link" {
  description = "Private DNS Resolver Virtual Network Link resource object."
  value       = azurerm_private_dns_resolver_virtual_network_link.main
}

output "module_vnet" {
  description = "Virtual Network module outputs."
  value       = module.vnet
}

output "module_subnets" {
  description = "Subnets module outputs."
  value       = module.subnets
}

output "id" {
  description = "Private DNS Resolver ID."
  value       = azurerm_private_dns_resolver.main.id
}

output "name" {
  description = "Private DNS Resolver name."
  value       = azurerm_private_dns_resolver.main.name
}

output "virtual_network_id" {
  description = "Private DNS Resolver Virtual Network ID."
  value       = local.vnet_id
}

output "virtual_network_name" {
  description = "Private DNS Resolver Virtual Network name."
  value       = local.vnet_name
}

output "inbound_endpoints" {
  description = "Maps of Private DNS Resolver inbound endpoints."
  value       = local.inbound_endpoints_output
}

output "outbound_endpoints" {
  description = "Maps of Private DNS Resolver outbound endpoints."
  value       = local.outbound_endpoints_output
}

output "dns_forwarding_rulesets" {
  description = "Maps of Private DNS Resolver DNS forwarding rulesets."
  value       = local.dns_forwarding_rulesets_output
}
