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

variable "vnet_id" {
  description = "ID of the existing VNet in which the Private DNS Resolver will be created. One of `vnet_id` or `vnet_cidr` must be specified."
  type        = string
  default     = ""
}

variable "vnet_cidr" {
  description = "CIDR of the VNet to create for the Private DNS Resolver. One of `vnet_id` or `vnet_cidr` must be specified."
  type        = string
  default     = ""
}

variable "inbound_endpoints" {
  description = <<EOD
List of Inbound Endpoint objects.
```
name               = Short Inbound Endpoint name, used to generate the Inbound Endpoint resource name.
cidr               = CIDR of the Inbound Endpoint Subnet.
custom_name        = Custom Inbound Endpoint name, overrides the Inbound Endpoint default resource name.
custom_subnet_name = Custom Subnet name, overrides the Subnet default resource name.
```
EOD
  type = list(object({
    name               = string
    cidr               = string
    custom_name        = optional(string)
    custom_subnet_name = optional(string)
  }))
  default = []
  validation {
    condition     = length(var.inbound_endpoints) <= 2
    error_message = "Inbound Endpoints are limited to 2 per Private DNS Resolver."
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
List of Outbound Endpoint objects.
```
name               = Short Outbound Endpoint name, used to generate the Outbound Endpoint resource name.
cidr               = CIDR of the Outbound Endpoint Subnet.
custom_name        = Custom Outbound Endpoint name, overrides the Outbound Endpoint default resource name.
custom_subnet_name = Custom Subnet name, overrides the Subnet default resource name.
```
EOD
  type = list(object({
    name               = string
    cidr               = string
    custom_name        = optional(string)
    custom_subnet_name = optional(string)
  }))
  default = []
  validation {
    condition     = length(var.outbound_endpoints) <= 2
    error_message = "Outbound Endpoints are limited to 2 per Private DNS Resolver."
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
List of DNS Forwarding Ruleset objects. The first DNS Forwarding Ruleset in the list is the default one because the VNet of the Private DNS Resolver is linked to it.
```
name                      = Short DNS Forwarding Ruleset name, used to generate the DNS Forwarding Ruleset resource name.
custom_name               = Custom DNS Forwarding Ruleset name, overrides the DNS Forwarding Ruleset default resource name.
target_outbound_endpoints = List of Outbound Endpoints to link to the DNS Forwarding Ruleset. Can be the short name of the Outbound Endpoint or an Oubound Endpoint ID.
vnets_ids                 = List of VNets IDs to link to the DNS Forwarding Ruleset.
rules                     = List of Forwarding Rule objects that the DNS Forwarding Ruleset contains.
  name            = Short Forwarding Rule name, used to generate the Forwarding Rule resource name.
  domain_name     = Specifies the target domain name of the Forwarding Rule. 
  dns_servers_ips = List of target DNS servers IPs for the specified domain name.
  custom_name     = Custom Forwarding Rule name, overrides the Forwarding Rule default resource name.
  enabled         = Whether the Forwarding Rule is enabled or not. Default to `true`.
```
EOD
  type = list(object({
    name                      = string
    custom_name               = optional(string)
    target_outbound_endpoints = optional(list(string), [])
    vnets_ids                 = optional(list(string), [])
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
    error_message = "Forwarding Rules are limited to 25 per DNS Forwarding Ruleset."
  }
  validation {
    condition     = alltrue([for ruleset in var.dns_forwarding_rulesets : length(ruleset.vnets_ids) <= 10])
    error_message = "VNet Links are limited to 10 per DNS Forwarding Ruleset."
  }
  validation {
    condition     = alltrue([for ruleset in var.dns_forwarding_rulesets : length(ruleset.target_outbound_endpoints) <= 2])
    error_message = "Outbound Endpoints are limited to 2 per DNS Forwarding Ruleset."
  }
  validation {
    condition = alltrue(flatten([
      for ruleset in var.dns_forwarding_rulesets : [
        for rule in ruleset.rules : length(rule.dns_servers_ips) <= 6
      ]
    ]))
    error_message = "Target DNS Servers are limited to 6 per Forwarding Rule."
  }
}
