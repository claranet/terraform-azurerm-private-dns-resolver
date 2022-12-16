module "azure_region" {
  source  = "claranet/regions/azurerm"
  version = "x.x.x"

  azure_region = var.azure_region
}

module "rg" {
  source  = "claranet/rg/azurerm"
  version = "x.x.x"

  location    = module.azure_region.location
  client_name = var.client_name
  environment = var.environment
  stack       = var.stack
}

module "my_vnet" {
  source  = "claranet/vnet/azurerm"
  version = "x.x.x"

  client_name    = var.client_name
  environment    = var.environment
  location       = module.azure_region.location
  location_short = module.azure_region.location_short
  stack          = var.stack

  resource_group_name = module.rg.resource_group_name

  custom_vnet_name = "my-vnet"

  vnet_cidr = [local.my_vnet_cidr]
}

module "vnets_to_be_linked" {
  source  = "claranet/vnet/azurerm"
  version = "x.x.x"

  count = length(local.vnets_cidrs_to_be_linked)

  client_name    = var.client_name
  environment    = var.environment
  location       = module.azure_region.location
  location_short = module.azure_region.location_short
  stack          = var.stack

  resource_group_name = module.rg.resource_group_name

  name_suffix = format("%02s", count.index + 1)

  vnet_cidr = [element(local.vnets_cidrs_to_be_linked, count.index)]
}

locals {
  my_vnet_cidr = "10.0.34.0/25"
  # my_subnets_cidrs = cidrsubnets(local.my_vnet_cidr, 2, 2, 2, 2)

  vnets_cidrs_to_be_linked = cidrsubnets("172.16.34.0/25", 3, 3, 3, 3, 3, 3, 3, 3)

  private_dns_resolver_vnet_cidr     = "192.168.34.0/25"
  private_dns_resolver_subnets_cidrs = cidrsubnets(local.private_dns_resolver_vnet_cidr, 2, 2, 2, 2)
}

module "private_dns_resolver" {
  source  = "claranet/private-dns-resolver/azurerm"
  version = "x.x.x"

  client_name    = var.client_name
  environment    = var.environment
  location       = module.azure_region.location
  location_short = module.azure_region.location_short
  stack          = var.stack

  resource_group_name = module.rg.resource_group_name

  ## Bring Your Own VNet
  # If set, `vnet_cidr` will not be used
  # vnet_id = module.my_vnet.virtual_network_id

  vnet_cidr = local.private_dns_resolver_vnet_cidr

  inbound_endpoints = [
    {
      name = "foo"
      cidr = local.private_dns_resolver_subnets_cidrs[0]
      # cidr = local.my_subnets_cidrs[0]
    },
    {
      name        = "bar"
      custom_name = "inbound-endpoint"
      cidr        = local.private_dns_resolver_subnets_cidrs[1]
      # cidr      = local.my_subnets_cidrs[1]
    },
  ]

  outbound_endpoints = [
    {
      name        = "foo"
      custom_name = "outbound-endpoint"
      cidr        = local.private_dns_resolver_subnets_cidrs[2]
      # cidr      = local.my_subnets_cidrs[2]
    },
    {
      name               = "bar"
      custom_subnet_name = "bar-outbound-endpoint-subnet"
      cidr               = local.private_dns_resolver_subnets_cidrs[3]
      # cidr             = local.my_subnets_cidrs[3]
    },
  ]

  dns_forwarding_rulesets = [
    # VNets cannot be linked to multiple Forwarding Ruleset     
    # Therefore, keep in mind that the first Ruleset is the default one because the VNet of the Private DNS Resolver is linked to this Ruleset
    {
      name        = "foo"
      custom_name = "forwarding-ruleset"

      # Ref to the first Outbound Endpoint
      target_outbound_endpoints = ["foo"]

      vnets_ids = slice(module.vnets_to_be_linked[*].virtual_network_id, 0, 4)

      rules = [
        {
          name            = "a"
          domain_name     = "a.foo.bar.com."
          dns_servers_ips = ["1.1.1.1", "2.2.2.2"]
        },
        {
          name            = "b"
          domain_name     = "b.foo.bar.com."
          dns_servers_ips = ["3.3.3.3"]
        },
      ]
    },
    {
      name = "bar"

      # Ref to all Outbound Endpoints
      # Can be an Oubound Endpoint ID, in case you want to use this DNS Forwarding Ruleset with an existing Outbound Endpoint
      target_outbound_endpoints = [
        "foo",
        "bar",
        # "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resourceGroup1/providers/Microsoft.Network/dnsResolvers/dnsResolver1/outboundEndpoints/outboundEndpoint1",
      ]

      vnets_ids = slice(module.vnets_to_be_linked[*].virtual_network_id, 4, 8)

      rules = [
        {
          name            = "c"
          domain_name     = "c.foo.bar.com."
          dns_servers_ips = ["4.4.4.4"]
        },
        {
          name            = "d"
          domain_name     = "d.foo.bar.com."
          dns_servers_ips = ["5.5.5.5"]
        },
      ]
    },
  ]
}
