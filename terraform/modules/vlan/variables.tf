# modules/vlan/variables.tf

# Basic VLAN configuration
variable "vlan_id" {
  type        = number
  description = "VLAN ID number (1-4094)"

  validation {
    condition     = var.vlan_id > 0 && var.vlan_id < 4095
    error_message = "VLAN ID must be between 1 and 4094."
  }
}

variable "bridge_name" {
  type        = string
  description = "Name of the bridge interface"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.bridge_name))
    error_message = "Bridge name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "vlan_cidr" {
  description = "Network CIDR for this VLAN (e.g., 192.168.10.0/24)"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vlan_cidr))
    error_message = "VLAN CIDR must be a valid CIDR notation (e.g., 192.168.10.0/24)."
  }
}

variable "gateway_ip" {
  description = "IP address for the VLAN interface that serves as gateway"
  type        = string

  validation {
    condition     = can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$", var.gateway_ip))
    error_message = "Gateway IP must be a valid IPv4 address."
  }
}

variable "description" {
  type        = string
  description = "Description of the VLAN"
  default     = ""
}

variable "disabled" {
  type        = bool
  description = "Whether the VLAN is disabled"
  default     = false
}

# Interface configuration
variable "interface_lists" {
  type        = list(string)
  description = "List of interface lists to add VLAN interface to"
}

variable "untagged_interfaces" {
  type        = list(string)
  description = "List of interfaces where traffic will be untagged for this VLAN"
  default     = []
}

variable "tagged_interfaces" {
  type        = list(string)
  description = "List of interfaces where traffic will remain tagged for this VLAN"
  default     = []
}

# DNS configuration
variable "dns_domain" {
  type        = string
  description = "Full DNS domain for DHCP clients (e.g., vlan10.example.com)"
}

# DHCP Configuration
variable "enable_dhcp" {
  type        = bool
  description = "Whether to enable DHCP server for this VLAN"
  default     = true
}

variable "dhcp_range_start" {
  description = "Start IP address for DHCP range"
  type        = string
  default     = null

  validation {
    condition     = var.dhcp_range_start == null || can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$", var.dhcp_range_start))
    error_message = "DHCP range start must be a valid IPv4 address."
  }
}

variable "dhcp_range_end" {
  description = "End IP address for DHCP range"
  type        = string
  default     = null

  validation {
    condition     = var.dhcp_range_end == null || can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$", var.dhcp_range_end))
    error_message = "DHCP range end must be a valid IPv4 address."
  }
}

variable "dhcp_lease_time" {
  type        = string
  description = "Lease time for DHCP assignments (e.g., '8h', '1d')"
  default     = "8h"
}

variable "dhcp_dns_servers" {
  type        = list(string)
  description = "List of DNS servers to provide via DHCP"
  default     = null
}

variable "dhcp_ntp_servers" {
  type        = list(string)
  description = "NTP server to provide via DHCP"
  default     = null
}

variable "dhcp_wins_servers" {
  type        = list(string)
  description = "WINS server to provide via DHCP (for Windows networks)"
  default     = null
}

variable "enable_dhcp_dns_update" {
  type        = bool
  description = "Whether to enable DHCP to DNS updates"
  default     = false
}

variable "static_dhcp_leases" {
  type = map(object({
    ip_address  = string
    mac_address = string
    hostname    = optional(string)
    client_id   = optional(string)
    dynamic     = optional(bool, false)
    blocked     = optional(bool, false)
  }))
  description = "Static DHCP leases for this VLAN"
  default     = {}
}

# Address Lists
variable "address_lists" {
  type = list(object({
    list     = string
    comment  = optional(string)
    disabled = optional(bool, false)
  }))
  description = "List of address lists to add the VLAN network to"
  default     = []
}

# Firewall configuration
variable "isolate_vlan" {
  type        = bool
  description = "Whether to isolate this VLAN from other VLANs"
  default     = true
}

variable "internet_access" {
  type        = bool
  description = "Whether this VLAN should have internet access"
  default     = true
}

variable "wan_interface" {
  type        = string
  description = "WAN interface name for masquerading/NAT"
}

variable "use_global_nat" {
  type        = bool
  description = "Whether to use global NAT masquerade instead of VLAN-specific rule"
  default     = true
}

variable "permitted_traffic" {
  type = list(object({
    destination = string
    protocol    = string
    port        = string
  }))
  description = "List of permitted traffic destinations from this VLAN"
  default     = []
}

variable "custom_firewall_rules" {
  type = list(object({
    action       = string
    chain        = string
    src_address  = optional(string)
    dst_address  = optional(string)
    protocol     = optional(string)
    dst_port     = optional(string)
    src_port     = optional(string)
    comment      = optional(string)
    place_before = optional(string)
  }))
  description = "Custom firewall rules for advanced configurations"
  default     = []
}

variable "security_zone" {
  type        = string
  description = "Security zone for this VLAN (internal, management, dmz)"
  default     = "internal"

  validation {
    condition     = contains(["internal", "management", "dmz"], var.security_zone)
    error_message = "Security zone must be one of: internal, management, dmz."
  }
}

variable "log_firewall" {
  type        = bool
  description = "Whether to log VLAN-specific firewall rules"
  default     = false
}

variable "log_prefix" {
  type        = string
  description = "Prefix for VLAN-specific firewall log entries"
  default     = ""
}

# Service permissions
variable "allow_dns" {
  type        = bool
  description = "Whether to allow DNS traffic to router"
  default     = true
}

variable "allow_ntp" {
  type        = bool
  description = "Whether to allow NTP traffic to router"
  default     = true
}

variable "allow_winbox" {
  type        = bool
  description = "Whether to allow Winbox traffic to router"
  default     = false
}

variable "allow_ssh" {
  type        = bool
  description = "Whether to allow SSH traffic to router"
  default     = false
}