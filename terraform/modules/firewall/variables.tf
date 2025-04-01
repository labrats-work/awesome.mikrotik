# modules/firewall/variables.tf

variable "wan_interface" {
  type        = string
  description = "Name of the WAN interface"
}

variable "enable_logging" {
  type        = bool
  description = "Enable logging for firewall rules"
  default     = true
}

variable "log_prefix" {
  type        = string
  description = "Prefix for firewall log entries"
  default     = "FIREWALL:"
}

variable "enable_global_nat" {
  type        = bool
  description = "Whether to enable global NAT masquerade for internal networks"
  default     = true
}

variable "rule_sets" {
  description = "List of rule sets to create"
  type = list(object({
    name     = string
    priority = number
    rules    = list(map(string))
  }))
}

variable "ensure_default_drops" {
  description = "Whether to ensure default drop rules exist at the end of input and forward chains"
  type        = bool
  default     = true
}

variable "custom_lists" {
  type = list(object({
    name      = string
    addresses = list(string)
    comment   = optional(string)
  }))
  description = "Custom address lists to create"
  default     = []
}

variable "enable_bogon_blocking" {
  type        = bool
  description = "Whether to block traffic from bogon networks"
  default     = true
}

variable "security_zones" {
  type = list(object({
    name           = string
    networks       = list(string)
    description    = string
    default_policy = string
  }))
  description = "Security zones to create"
  default = [
    {
      name           = "internal"
      networks       = []
      description    = "Internal networks"
      default_policy = "accept"
    },
    {
      name           = "management"
      networks       = []
      description    = "Management networks"
      default_policy = "drop"
    },
    {
      name           = "dmz"
      networks       = []
      description    = "DMZ networks"
      default_policy = "drop"
    }
  ]
}