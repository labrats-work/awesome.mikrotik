# modules/monitoring/variables.tf
variable "snmp_community" {
  type        = string
  description = "SNMP community string"
  default     = "public"

  validation {
    condition     = length(var.snmp_community) >= 5
    error_message = "SNMP community string should be at least 5 characters for security."
  }
}

variable "snmp_contact" {
  type        = string
  description = "Contact information for SNMP"
  default     = "admin@example.com"
}

variable "snmp_location" {
  type        = string
  description = "Physical location of the device"
  default     = "Server Room"
}

variable "allowed_networks" {
  type        = list(string)
  description = "Networks allowed to query via SNMP"
  default     = []
}

# modules/monitoring/main.tf
resource "routeros_snmp" "this" {
  enabled        = true
  contact        = var.snmp_contact
  location       = var.snmp_location
  trap_community = var.snmp_community
}

resource "routeros_snmp_community" "this" {
  name      = var.snmp_community
  addresses = length(var.allowed_networks) > 0 ? var.allowed_networks : null
}

# modules/monitoring/outputs.tf
output "snmp_enabled" {
  description = "Whether SNMP is enabled"
  value       = routeros_snmp.this.enabled
}

output "snmp_community" {
  description = "SNMP community string"
  value       = routeros_snmp_community.this.name
  sensitive   = true
}