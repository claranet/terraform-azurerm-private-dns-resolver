variable "location" {
  description = "Azure location."
  type        = string
}

variable "location_short" {
  description = "Short string for Azure location."
  type        = string
}

variable "client_name" {
  description = "Client name/account used in naming."
  type        = string
}

variable "environment" {
  description = "Project environment."
  type        = string
}

variable "stack" {
  description = "Project stack name."
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group name."
  type        = string
}

variable "virtual_network_id" {
  description = "ID of the existing Virtual Network in which the Private DNS Resolver will be created. One of `virtual_network_id` or `virtual_network_cidr` must be specified."
  type        = string
  default     = ""
}

variable "virtual_network_cidr" {
  description = "CIDR of the Virtual Network to create for the Private DNS Resolver. One of `virtual_network_id` or `virtual_network_cidr` must be specified."
  type        = string
  default     = ""
}

variable "inbound_endpoints" {
  description = <<EOD
List of inbound endpoint objects.
```
name                            = Short inbound endpoint name, used to generate the inbound endpoint resource name.
cidr                            = CIDR of the inbound endpoint Subnet.
custom_name                     = Custom inbound endpoint name, overrides the inbound endpoint default resource name.
subnet_custom_name              = Custom Subnet name, overrides the Subnet default resource name.
default_outbound_access_enabled	= Enable or disable default outbound access in Azure. See [documentation](https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/default-outbound-access).
```
EOD
  type = list(object({
    name                            = string
    cidr                            = string
    custom_name                     = optional(string)
    subnet_custom_name              = optional(string)
    default_outbound_access_enabled = optional(bool, false)
  }))
  default = []
  validation {
    condition     = length(var.inbound_endpoints) <= 2
    error_message = "Inbound endpoints are limited to 2 per Private DNS Resolver."
  }
  validation {
    condition     = alltrue([for endpoint in var.inbound_endpoints : !contains([for r in range(1, 17) : format("10.0.%s", r)], replace(cidrsubnet(endpoint.cidr, 0, 0), "/(.+)\\.[0-9]{1,3}\\/[1-9]{1,2}/", "$1"))])
    error_message = "The following IP address space is reserved by the service and cannot be used: '10.0.1.0 - 10.0.16.255'."
  }
  validation {
    condition     = alltrue([for endpoint in var.inbound_endpoints : contains([for r in range(24, 29) : format("/%s", r)], replace(endpoint.cidr, "/(.+)(\\/[1-9]{1,2})/", "$2"))])
    error_message = "The Subnet must be a minimum of /28 or a maximum of /24 address space."
  }
}

variable "outbound_endpoints" {
  description = <<EOD
List of outbound endpoint objects.
```
name                            = Short outbound endpoint name, used to generate the outbound endpoint resource name.
cidr                            = CIDR of the outbound endpoint Subnet.
custom_name                     = Custom outbound endpoint name, overrides the outbound endpoint default resource name.
subnet_custom_name              = Custom Subnet name, overrides the Subnet default resource name.
default_outbound_access_enabled	= Enable or disable default outbound access in Azure. See [documentation](https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/default-outbound-access).
```
EOD
  type = list(object({
    name                            = string
    cidr                            = string
    custom_name                     = optional(string)
    subnet_custom_name              = optional(string)
    default_outbound_access_enabled = optional(bool, false)
  }))
  default = []
  validation {
    condition     = length(var.outbound_endpoints) <= 2
    error_message = "Outbound endpoints are limited to 2 per Private DNS Resolver."
  }
  validation {
    condition     = alltrue([for endpoint in var.outbound_endpoints : !contains([for r in range(1, 17) : format("10.0.%s", r)], replace(cidrsubnet(endpoint.cidr, 0, 0), "/(.+)\\.[0-9]{1,3}\\/[1-9]{1,2}/", "$1"))])
    error_message = "The following IP address space is reserved by the service and cannot be used: '10.0.1.0 - 10.0.16.255'."
  }
  validation {
    condition     = alltrue([for endpoint in var.outbound_endpoints : contains([for r in range(24, 29) : format("/%s", r)], replace(endpoint.cidr, "/(.+)(\\/[1-9]{1,2})/", "$2"))])
    error_message = "The Subnet must be a minimum of /28 or a maximum of /24 address space."
  }
}

variable "dns_forwarding_rulesets" {
  description = <<EOD
List of DNS forwarding ruleset objects. The first DNS forwarding ruleset in the list is the default one because the Virtual Network of the Private DNS Resolver is linked to it.
```
name                      = Short DNS forwarding ruleset name, used to generate the DNS forwarding ruleset resource name.
custom_name               = Custom DNS forwarding ruleset name, overrides the DNS forwarding ruleset default resource name.
target_outbound_endpoints = List of outbound endpoints to link to the DNS forwarding ruleset. Can be the short name of the outbound endpoint or an outbound endpoint ID.
virtual_networks_ids      = List of Virtual Networks IDs to link to the DNS forwarding ruleset.
rules                     = List of forwarding rule objects that the DNS forwarding ruleset contains.
  name            = Short forwarding rule name, used to generate the forwarding rule resource name.
  domain_name     = Specifies the target domain name of the forwarding rule.
  dns_servers_ips = List of target DNS servers IPs for the specified domain name.
  custom_name     = Custom forwarding rule name, overrides the forwarding rule default resource name.
  enabled         = Whether the forwarding rule is enabled or not. Default to `true`.
```
EOD
  type = list(object({
    name                      = string
    custom_name               = optional(string)
    target_outbound_endpoints = optional(list(string), [])
    virtual_networks_ids      = optional(list(string), [])
    rules = optional(list(object({
      name            = string
      domain_name     = string
      dns_servers_ips = list(string)
      custom_name     = optional(string)
      enabled         = optional(bool, true)
    })), [])
  }))
  default = []
  validation {
    condition     = alltrue([for ruleset in var.dns_forwarding_rulesets : length(ruleset.rules) <= 25])
    error_message = "Forwarding rules are limited to 25 per DNS forwarding ruleset."
  }
  validation {
    condition     = alltrue([for ruleset in var.dns_forwarding_rulesets : length(ruleset.virtual_networks_ids) <= 10])
    error_message = "Virtual Network links are limited to 10 per DNS forwarding ruleset."
  }
  validation {
    condition     = alltrue([for ruleset in var.dns_forwarding_rulesets : length(ruleset.target_outbound_endpoints) <= 2])
    error_message = "Outbound endpoints are limited to 2 per DNS forwarding ruleset."
  }
  validation {
    condition = alltrue(flatten([
      for ruleset in var.dns_forwarding_rulesets : [
        for rule in ruleset.rules : length(rule.dns_servers_ips) <= 6
      ]
    ]))
    error_message = "Target DNS Servers are limited to 6 per forwarding rule."
  }
}
