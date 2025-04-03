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