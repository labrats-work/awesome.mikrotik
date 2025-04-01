# modules/vlan/outputs.tf

output "vlan_name" {
  description = "Name of the created VLAN interface"
  value       = routeros_interface_vlan.this.name
}

output "vlan_id" {
  description = "ID of the VLAN"
  value       = var.vlan_id
}

output "network_cidr" {
  description = "Network CIDR block assigned to the VLAN"
  value       = var.vlan_cidr
}

output "gateway_ip" {
  description = "IP address of the VLAN interface (gateway)"
  value       = var.gateway_ip
}

output "dhcp_range" {
  description = "DHCP address range for this VLAN"
  value       = var.enable_dhcp ? "${local.dhcp_address_start}-${local.dhcp_address_end}" : null
}

output "domain" {
  description = "DNS domain name for this VLAN"
  value       = var.dns_domain
}

output "security_zone" {
  description = "Security zone for this VLAN"
  value       = var.security_zone
}

output "interface_id" {
  description = "RouterOS ID of the VLAN interface"
  value       = routeros_interface_vlan.this.id
}

output "is_management" {
  description = "Whether this VLAN is a management VLAN"
  value       = var.security_zone == "management"
}

output "is_dmz" {
  description = "Whether this VLAN is a DMZ VLAN"
  value       = var.security_zone == "dmz"
}

output "firewall_rule_sets" {
  description = "Firewall rule sets needed for this VLAN"
  value       = [for set in local.firewall_rule_sets : set if set != null]
}