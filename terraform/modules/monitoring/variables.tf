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
