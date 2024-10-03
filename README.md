# Azure Private DNS Resolver

[![Changelog](https://img.shields.io/badge/changelog-release-green.svg)](CHANGELOG.md) [![Notice](https://img.shields.io/badge/notice-copyright-blue.svg)](NOTICE) [![Apache V2 License](https://img.shields.io/badge/license-Apache%20V2-orange.svg)](LICENSE) [![OpenTofu Registry](https://img.shields.io/badge/opentofu-registry-yellow.svg)](https://search.opentofu.org/module/claranet/private-dns-resolver/azurerm/)

This Terraform module creates an [Azure Private DNS Resolver](https://learn.microsoft.com/en-us/azure/dns/dns-private-resolver-overview/).

<!-- BEGIN_TF_DOCS -->
## Global versioning rule for Claranet Azure modules

| Module version | Terraform version | AzureRM version |
| -------------- | ----------------- | --------------- |
| >= 7.x.x       | 1.3.x             | >= 3.0          |
| >= 6.x.x       | 1.x               | >= 3.0          |
| >= 5.x.x       | 0.15.x            | >= 2.0          |
| >= 4.x.x       | 0.13.x / 0.14.x   | >= 2.0          |
| >= 3.x.x       | 0.12.x            | >= 2.0          |
| >= 2.x.x       | 0.12.x            | < 2.0           |
| <  2.x.x       | 0.11.x            | < 2.0           |

## Contributing

If you want to contribute to this repository, feel free to use our [pre-commit](https://pre-commit.com/) git hook configuration
which will help you automatically update and format some files for you by enforcing our Terraform code module best-practices.

More details are available in the [CONTRIBUTING.md](./CONTRIBUTING.md#pull-request-process) file.

## Usage

This module is optimized to work with the [Claranet terraform-wrapper](https://github.com/claranet/terraform-wrapper) tool
which set some terraform variables in the environment needed by this module.
More details about variables set by the `terraform-wrapper` available in the [documentation](https://github.com/claranet/terraform-wrapper#environment).

```hcl
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
```

## Providers

| Name | Version |
|------|---------|
| azurecaf | ~> 1.2, >= 1.2.22 |
| azurerm | ~> 3.107 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| subnets | claranet/subnet/azurerm | 7.2.0 |
| vnet | claranet/vnet/azurerm | 7.0.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_private_dns_resolver.private_dns_resolver](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver) | resource |
| [azurerm_private_dns_resolver_dns_forwarding_ruleset.dns_forwarding_rulesets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver_dns_forwarding_ruleset) | resource |
| [azurerm_private_dns_resolver_forwarding_rule.forwarding_rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver_forwarding_rule) | resource |
| [azurerm_private_dns_resolver_inbound_endpoint.inbound_endpoints](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver_inbound_endpoint) | resource |
| [azurerm_private_dns_resolver_outbound_endpoint.outbound_endpoints](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver_outbound_endpoint) | resource |
| [azurerm_private_dns_resolver_virtual_network_link.vnet_links](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver_virtual_network_link) | resource |
| [azurecaf_name.dns_forwarding_rulesets](https://registry.terraform.io/providers/claranet/azurecaf/latest/docs/data-sources/name) | data source |
| [azurecaf_name.forwarding_rules](https://registry.terraform.io/providers/claranet/azurecaf/latest/docs/data-sources/name) | data source |
| [azurecaf_name.inbound_endpoints](https://registry.terraform.io/providers/claranet/azurecaf/latest/docs/data-sources/name) | data source |
| [azurecaf_name.outbound_endpoints](https://registry.terraform.io/providers/claranet/azurecaf/latest/docs/data-sources/name) | data source |
| [azurecaf_name.private_dns_resolver](https://registry.terraform.io/providers/claranet/azurecaf/latest/docs/data-sources/name) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| client\_name | Client name/account used in naming. | `string` | n/a | yes |
| custom\_private\_dns\_resolver\_name | Custom Private DNS Resolver name, generated if not set. | `string` | `""` | no |
| custom\_vnet\_name | Custom VNet name, generated if not set. | `string` | `""` | no |
| default\_tags\_enabled | Option to enable or disable default tags. | `bool` | `true` | no |
| dns\_forwarding\_rulesets | List of DNS Forwarding Ruleset objects. The first DNS Forwarding Ruleset in the list is the default one because the VNet of the Private DNS Resolver is linked to it.<pre>name                      = Short DNS Forwarding Ruleset name, used to generate the DNS Forwarding Ruleset resource name.<br/>custom_name               = Custom DNS Forwarding Ruleset name, overrides the DNS Forwarding Ruleset default resource name.<br/>target_outbound_endpoints = List of Outbound Endpoints to link to the DNS Forwarding Ruleset. Can be the short name of the Outbound Endpoint or an Oubound Endpoint ID.<br/>vnets_ids                 = List of VNets IDs to link to the DNS Forwarding Ruleset.<br/>rules                     = List of Forwarding Rule objects that the DNS Forwarding Ruleset contains.<br/>  name            = Short Forwarding Rule name, used to generate the Forwarding Rule resource name.<br/>  domain_name     = Specifies the target domain name of the Forwarding Rule.<br/>  dns_servers_ips = List of target DNS servers IPs for the specified domain name.<br/>  custom_name     = Custom Forwarding Rule name, overrides the Forwarding Rule default resource name.<br/>  enabled         = Whether the Forwarding Rule is enabled or not. Default to `true`.</pre> | <pre>list(object({<br/>    name                      = string<br/>    custom_name               = optional(string)<br/>    target_outbound_endpoints = optional(list(string), [])<br/>    vnets_ids                 = optional(list(string), [])<br/>    rules = optional(list(object({<br/>      name            = string<br/>      domain_name     = string<br/>      dns_servers_ips = list(string)<br/>      custom_name     = optional(string)<br/>      enabled         = optional(bool, true)<br/>    })), [])<br/>  }))</pre> | `[]` | no |
| environment | Project environment. | `string` | n/a | yes |
| extra\_tags | Extra tags to add. | `map(string)` | `{}` | no |
| inbound\_endpoints | List of Inbound Endpoint objects.<pre>name               = Short Inbound Endpoint name, used to generate the Inbound Endpoint resource name.<br/>cidr               = CIDR of the Inbound Endpoint Subnet.<br/>custom_name        = Custom Inbound Endpoint name, overrides the Inbound Endpoint default resource name.<br/>custom_subnet_name = Custom Subnet name, overrides the Subnet default resource name.</pre> | <pre>list(object({<br/>    name               = string<br/>    cidr               = string<br/>    custom_name        = optional(string)<br/>    custom_subnet_name = optional(string)<br/>  }))</pre> | `[]` | no |
| location | Azure location. | `string` | n/a | yes |
| location\_short | Short string for Azure location. | `string` | n/a | yes |
| name\_prefix | Optional prefix for the generated name. | `string` | `""` | no |
| name\_suffix | Optional suffix for the generated name. | `string` | `""` | no |
| outbound\_endpoints | List of Outbound Endpoint objects.<pre>name               = Short Outbound Endpoint name, used to generate the Outbound Endpoint resource name.<br/>cidr               = CIDR of the Outbound Endpoint Subnet.<br/>custom_name        = Custom Outbound Endpoint name, overrides the Outbound Endpoint default resource name.<br/>custom_subnet_name = Custom Subnet name, overrides the Subnet default resource name.</pre> | <pre>list(object({<br/>    name               = string<br/>    cidr               = string<br/>    custom_name        = optional(string)<br/>    custom_subnet_name = optional(string)<br/>  }))</pre> | `[]` | no |
| resource\_group\_name | Resource Group name. | `string` | n/a | yes |
| stack | Project stack name. | `string` | n/a | yes |
| use\_caf\_naming | Use the Azure CAF naming provider to generate default resource name. Custom names override this if set. Legacy default names is used if this is set to `false`. | `bool` | `true` | no |
| vnet\_cidr | CIDR of the VNet to create for the Private DNS Resolver. One of `vnet_id` or `vnet_cidr` must be specified. | `string` | `""` | no |
| vnet\_id | ID of the existing VNet in which the Private DNS Resolver will be created. One of `vnet_id` or `vnet_cidr` must be specified. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| dns\_forwarding\_rulesets | Maps of Private DNS Resolver DNS Forwarding Rulesets outputs. |
| inbound\_endpoints | Maps of Private DNS Resolver Inbound Endpoints outputs. |
| outbound\_endpoints | Maps of Private DNS Resolver Outbound Endpoints outputs. |
| private\_dns\_resolver | Private DNS Resolver outputs. |
<!-- END_TF_DOCS -->

## Related documentation

Microsoft Azure documentation: [learn.microsoft.com/en-us/azure/dns/dns-private-resolver-overview/](https://learn.microsoft.com/en-us/azure/dns/dns-private-resolver-overview/)
