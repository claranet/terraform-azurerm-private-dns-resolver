locals {
  my_vnet_cidr = "10.0.34.0/25"
  # my_subnets_cidrs = cidrsubnets(local.my_vnet_cidr, 2, 2, 2, 2)

  vnets_cidrs_to_be_linked = cidrsubnets("172.16.34.0/25", 3, 3, 3, 3, 3, 3, 3, 3)

  private_dns_resolver_vnet_cidr     = "192.168.34.0/25"
  private_dns_resolver_subnets_cidrs = cidrsubnets(local.private_dns_resolver_vnet_cidr, 2, 2, 2, 2)
}

module "my_vnet" {
  source  = "claranet/vnet/azurerm"
  version = "x.x.x"

  location       = module.azure_region.location
  location_short = module.azure_region.location_short
  client_name    = var.client_name
  environment    = var.environment
  stack          = var.stack

  resource_group_name = module.rg.name

  custom_name = "my-vnet"

  cidrs = [local.my_vnet_cidr]
}

module "vnets_to_be_linked" {
  source  = "claranet/vnet/azurerm"
  version = "x.x.x"

  count = length(local.vnets_cidrs_to_be_linked)

  location       = module.azure_region.location
  location_short = module.azure_region.location_short
  client_name    = var.client_name
  environment    = var.environment
  stack          = var.stack

  resource_group_name = module.rg.name

  name_suffix = format("%02s", count.index + 1)

  cidrs = [element(local.vnets_cidrs_to_be_linked, count.index)]
}

module "private_dns_resolver" {
  source  = "claranet/private-dns-resolver/azurerm"
  version = "x.x.x"

  location       = module.azure_region.location
  location_short = module.azure_region.location_short
  client_name    = var.client_name
  environment    = var.environment
  stack          = var.stack

  resource_group_name = module.rg.name

  ## Bring Your Own VNet
  # If set, `virtual_network_id` will not be used
  # virtual_network_id = module.my_vnet.id

  virtual_network_cidr = local.private_dns_resolver_vnet_cidr

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
      default_outbound_access_enabled = true
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
      subnet_custom_name = "bar-outbound-endpoint-subnet"
      cidr               = local.private_dns_resolver_subnets_cidrs[3]
      # cidr             = local.my_subnets_cidrs[3]
    },
  ]

  dns_forwarding_rulesets = [
    # Virtual Networks cannot be linked to multiple forwarding ruleset
    # Therefore, keep in mind that the first ruleset is the default one because the Virtual Network of the Private DNS Resolver is linked to this ruleset
    {
      name        = "foo"
      custom_name = "forwarding-ruleset"

      # Ref to the first outbound endpoint
      target_outbound_endpoints = ["foo"]

      virtual_networks_ids = slice(module.vnets_to_be_linked[*].id, 0, 4)

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

      # Ref to all outbound endpoints
      # Can be an outbound endpoint ID, in case you want to use this DNS forwarding ruleset with an existing outbound endpoint
      target_outbound_endpoints = [
        "foo",
        "bar",
        # "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/resourceGroup1/providers/Microsoft.Network/dnsResolvers/dnsResolver1/outboundEndpoints/outboundEndpoint1",
      ]

      virtual_networks_ids = slice(module.vnets_to_be_linked[*].id, 4, 8)

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
