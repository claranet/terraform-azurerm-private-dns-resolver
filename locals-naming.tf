locals {
  # Naming locals/constants
  name_prefix = lower(var.name_prefix)
  name_suffix = lower(var.name_suffix)

  private_dns_resolver_name = coalesce(var.custom_private_dns_resolver_name, data.azurecaf_name.private_dns_resolver.result)
}
