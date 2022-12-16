# Generic naming variables
variable "name_prefix" {
  description = "Optional prefix for the generated name."
  type        = string
  default     = ""
}

variable "name_suffix" {
  description = "Optional suffix for the generated name."
  type        = string
  default     = ""
}

variable "use_caf_naming" {
  description = "Use the Azure CAF naming provider to generate default resource name. Custom names override this if set. Legacy default names is used if this is set to `false`."
  type        = bool
  default     = true
}

# Custom naming override
variable "custom_vnet_name" {
  description = "Custom VNet name, generated if not set."
  type        = string
  default     = ""
}

variable "custom_private_dns_resolver_name" {
  description = "Custom Private DNS Resolver name, generated if not set."
  type        = string
  default     = ""
}
