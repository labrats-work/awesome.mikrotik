# modules/ntp/outputs.tf
output "ntp_servers" {
  description = "Configured NTP servers"
  value       = routeros_system_ntp_client.this.servers
}

output "timezone" {
  description = "Configured timezone"
  value       = routeros_system_clock.this.time_zone_name
}