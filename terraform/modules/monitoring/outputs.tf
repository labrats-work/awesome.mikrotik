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