# modules/ntp/variables.tf
variable "ntp_servers" {
  type        = list(string)
  description = "List of NTP server addresses"
  default     = ["pool.ntp.org", "time.google.com"]
}

variable "timezone" {
  type        = string
  description = "System timezone"
  default     = "UTC"
}

# modules/ntp/main.tf
resource "routeros_system_ntp_client" "this" {
  enabled = true
  servers = var.ntp_servers
}

resource "routeros_system_clock" "this" {
  time_zone_name = var.timezone
}

# modules/ntp/outputs.tf
output "ntp_servers" {
  description = "Configured NTP servers"
  value       = routeros_system_ntp_client.this.servers
}

output "timezone" {
  description = "Configured timezone"
  value       = routeros_system_clock.this.time_zone_name
}