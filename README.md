# Azure Private DNS Resolver

[![Changelog](https://img.shields.io/badge/changelog-release-green.svg)](CHANGELOG.md) [![Notice](https://img.shields.io/badge/notice-copyright-blue.svg)](NOTICE) [![Apache V2 License](https://img.shields.io/badge/license-Apache%20V2-orange.svg)](LICENSE) [![OpenTofu Registry](https://img.shields.io/badge/opentofu-registry-yellow.svg)](https://search.opentofu.org/module/claranet/private-dns-resolver/azurerm/)

This Terraform module creates an [Azure Private DNS Resolver](https://learn.microsoft.com/en-us/azure/dns/dns-private-resolver-overview/).

<!-- BEGIN_TF_DOCS -->
## Global versioning rule for Claranet Azure modules

| Module version | Terraform version | OpenTofu version | AzureRM version |
| -------------- | ----------------- | ---------------- | --------------- |
| >= 8.x.x       | **Unverified**    | 1.8.x            | >= 4.0          |
| >= 7.x.x       | 1.3.x             |                  | >= 3.0          |
| >= 6.x.x       | 1.x               |                  | >= 3.0          |
| >= 5.x.x       | 0.15.x            |                  | >= 2.0          |
| >= 4.x.x       | 0.13.x / 0.14.x   |                  | >= 2.0          |
| >= 3.x.x       | 0.12.x            |                  | >= 2.0          |
| >= 2.x.x       | 0.12.x            |                  | < 2.0           |
| <  2.x.x       | 0.11.x            |                  | < 2.0           |

## Contributing

If you want to contribute to this repository, feel free to use our [pre-commit](https://pre-commit.com/) git hook configuration
which will help you automatically update and format some files for you by enforcing our Terraform code module best-practices.

More details are available in the [CONTRIBUTING.md](./CONTRIBUTING.md#pull-request-process) file.

## Usage

This module is optimized to work with the [Claranet terraform-wrapper](https://github.com/claranet/terraform-wrapper) tool
which set some terraform variables in the environment needed by this module.
More details about variables set by the `terraform-wrapper` available in the [documentation](https://github.com/claranet/terraform-wrapper#environment).

⚠️ Since modules version v8.0.0, we do not maintain/check anymore the compatibility with
[Hashicorp Terraform](https://github.com/hashicorp/terraform/). Instead, we recommend to use [OpenTofu](https://github.com/opentofu/opentofu/).

```hcl
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
```

## Providers

| Name | Version |
|------|---------|
| azurecaf | ~> 1.2.28 |
| azurerm | ~> 4.13 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| subnets | claranet/subnet/azurerm | ~> 8.1.0 |
| vnet | claranet/vnet/azurerm | ~> 8.1.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_private_dns_resolver.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver) | resource |
| [azurerm_private_dns_resolver_dns_forwarding_ruleset.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver_dns_forwarding_ruleset) | resource |
| [azurerm_private_dns_resolver_forwarding_rule.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver_forwarding_rule) | resource |
| [azurerm_private_dns_resolver_inbound_endpoint.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver_inbound_endpoint) | resource |
| [azurerm_private_dns_resolver_outbound_endpoint.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver_outbound_endpoint) | resource |
| [azurerm_private_dns_resolver_virtual_network_link.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver_virtual_network_link) | resource |
| [azurecaf_name.dns_forwarding_rulesets](https://registry.terraform.io/providers/claranet/azurecaf/latest/docs/data-sources/name) | data source |
| [azurecaf_name.forwarding_rules](https://registry.terraform.io/providers/claranet/azurecaf/latest/docs/data-sources/name) | data source |
| [azurecaf_name.inbound_endpoints](https://registry.terraform.io/providers/claranet/azurecaf/latest/docs/data-sources/name) | data source |
| [azurecaf_name.outbound_endpoints](https://registry.terraform.io/providers/claranet/azurecaf/latest/docs/data-sources/name) | data source |
| [azurecaf_name.private_dns_resolver](https://registry.terraform.io/providers/claranet/azurecaf/latest/docs/data-sources/name) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| client\_name | Client name/account used in naming. | `string` | n/a | yes |
| custom\_name | Custom Private DNS Resolver name, generated if not set. | `string` | `""` | no |
| default\_tags\_enabled | Option to enable or disable default tags. | `bool` | `true` | no |
| dns\_forwarding\_rulesets | List of DNS forwarding ruleset objects. The first DNS forwarding ruleset in the list is the default one because the Virtual Network of the Private DNS Resolver is linked to it.<pre>name                      = Short DNS forwarding ruleset name, used to generate the DNS forwarding ruleset resource name.<br/>custom_name               = Custom DNS forwarding ruleset name, overrides the DNS forwarding ruleset default resource name.<br/>target_outbound_endpoints = List of outbound endpoints to link to the DNS forwarding ruleset. Can be the short name of the outbound endpoint or an outbound endpoint ID.<br/>virtual_networks_ids      = List of Virtual Networks IDs to link to the DNS forwarding ruleset.<br/>rules                     = List of forwarding rule objects that the DNS forwarding ruleset contains.<br/>  name            = Short forwarding rule name, used to generate the forwarding rule resource name.<br/>  domain_name     = Specifies the target domain name of the forwarding rule.<br/>  dns_servers_ips = List of target DNS servers IPs for the specified domain name.<br/>  custom_name     = Custom forwarding rule name, overrides the forwarding rule default resource name.<br/>  enabled         = Whether the forwarding rule is enabled or not. Default to `true`.</pre> | <pre>list(object({<br/>    name                      = string<br/>    custom_name               = optional(string)<br/>    target_outbound_endpoints = optional(list(string), [])<br/>    virtual_networks_ids      = optional(list(string), [])<br/>    rules = optional(list(object({<br/>      name            = string<br/>      domain_name     = string<br/>      dns_servers_ips = list(string)<br/>      custom_name     = optional(string)<br/>      enabled         = optional(bool, true)<br/>    })), [])<br/>  }))</pre> | `[]` | no |
| environment | Project environment. | `string` | n/a | yes |
| extra\_tags | Extra tags to add. | `map(string)` | `{}` | no |
| inbound\_endpoints | List of inbound endpoint objects.<pre>name                            = Short inbound endpoint name, used to generate the inbound endpoint resource name.<br/>cidr                            = CIDR of the inbound endpoint Subnet.<br/>custom_name                     = Custom inbound endpoint name, overrides the inbound endpoint default resource name.<br/>subnet_custom_name              = Custom Subnet name, overrides the Subnet default resource name.<br/>default_outbound_access_enabled	= Enable or disable default outbound access in Azure. See [documentation](https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/default-outbound-access).</pre> | <pre>list(object({<br/>    name                            = string<br/>    cidr                            = string<br/>    custom_name                     = optional(string)<br/>    subnet_custom_name              = optional(string)<br/>    default_outbound_access_enabled = optional(bool, false)<br/>  }))</pre> | `[]` | no |
| location | Azure location. | `string` | n/a | yes |
| location\_short | Short string for Azure location. | `string` | n/a | yes |
| name\_prefix | Optional prefix for the generated name. | `string` | `""` | no |
| name\_suffix | Optional suffix for the generated name. | `string` | `""` | no |
| outbound\_endpoints | List of outbound endpoint objects.<pre>name                            = Short outbound endpoint name, used to generate the outbound endpoint resource name.<br/>cidr                            = CIDR of the outbound endpoint Subnet.<br/>custom_name                     = Custom outbound endpoint name, overrides the outbound endpoint default resource name.<br/>subnet_custom_name              = Custom Subnet name, overrides the Subnet default resource name.<br/>default_outbound_access_enabled	= Enable or disable default outbound access in Azure. See [documentation](https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/default-outbound-access).</pre> | <pre>list(object({<br/>    name                            = string<br/>    cidr                            = string<br/>    custom_name                     = optional(string)<br/>    subnet_custom_name              = optional(string)<br/>    default_outbound_access_enabled = optional(bool, false)<br/>  }))</pre> | `[]` | no |
| resource\_group\_name | Resource Group name. | `string` | n/a | yes |
| stack | Project stack name. | `string` | n/a | yes |
| virtual\_network\_cidr | CIDR of the Virtual Network to create for the Private DNS Resolver. One of `virtual_network_id` or `virtual_network_cidr` must be specified. | `string` | `""` | no |
| virtual\_network\_custom\_name | Custom Virtual Network name, generated if not set. | `string` | `""` | no |
| virtual\_network\_id | ID of the existing Virtual Network in which the Private DNS Resolver will be created. One of `virtual_network_id` or `virtual_network_cidr` must be specified. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| dns\_forwarding\_rulesets | Maps of Private DNS Resolver DNS forwarding rulesets. |
| id | Private DNS Resolver ID. |
| inbound\_endpoints | Maps of Private DNS Resolver inbound endpoints. |
| module\_subnets | Subnets module outputs. |
| module\_virtual\_network | Virtual Network module outputs. |
| name | Private DNS Resolver name. |
| outbound\_endpoints | Maps of Private DNS Resolver outbound endpoints. |
| resource | Private DNS Resolver resource object. |
| resource\_dns\_forwarding\_ruleset | Private DNS Resolver DNS forwarding ruleset resource object. |
| resource\_forwarding\_rule | Private DNS Resolver forwarding rule resource object. |
| resource\_inbound\_endpoint | Private DNS Resolver inbound endpoint resource object. |
| resource\_outbound\_endpoint | Private DNS Resolver outbound endpoint resource object. |
| resource\_virtual\_network\_link | Private DNS Resolver Virtual Network Link resource object. |
| virtual\_network\_id | Private DNS Resolver Virtual Network ID. |
| virtual\_network\_name | Private DNS Resolver Virtual Network name. |
<!-- END_TF_DOCS -->

## Related documentation

Microsoft Azure documentation: [learn.microsoft.com/en-us/azure/dns/dns-private-resolver-overview/](https://learn.microsoft.com/en-us/azure/dns/dns-private-resolver-overview/)
