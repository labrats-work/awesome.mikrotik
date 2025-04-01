# modules/vlan/dhcp.tf

# Create DHCP pool for the VLAN
resource "routeros_ip_pool" "this" {
  count   = var.enable_dhcp ? 1 : 0
  name    = local.vlan_name
  comment = "DHCP pool for ${local.vlan_name}"
  ranges  = ["${local.dhcp_address_start}-${local.dhcp_address_end}"]
}

# Create DHCP server for the VLAN
resource "routeros_ip_dhcp_server" "this" {
  count        = var.enable_dhcp ? 1 : 0
  name         = local.vlan_name
  comment      = "DHCP server for ${local.vlan_name}"
  address_pool = routeros_ip_pool.this[0].name
  interface    = routeros_interface_vlan.this.name
  lease_time   = var.dhcp_lease_time

  # Optional DHCP to DNS update script
  lease_script = var.enable_dhcp_dns_update ? templatefile("${path.module}/templates/dhcp_dns_update.rsc", {
    vlan_name = local.vlan_name
  }) : null

  add_arp  = true
  disabled = var.disabled
}

# Configure DHCP network settings
resource "routeros_ip_dhcp_server_network" "this" {
  count      = var.enable_dhcp ? 1 : 0
  comment    = "DHCP network for ${local.vlan_name}"
  address    = var.vlan_cidr
  gateway    = var.gateway_ip
  dns_server = var.dhcp_dns_servers != null ? var.dhcp_dns_servers : [var.gateway_ip]
  domain     = var.dns_domain

  # Optional NTP server
  ntp_server = var.dhcp_ntp_servers != null ? var.dhcp_ntp_servers : null

  # Optional WINS server for Windows networks
  wins_server = var.dhcp_wins_servers != null ? var.dhcp_wins_servers : null
}

# Static DHCP leases if configured
resource "routeros_ip_dhcp_server_lease" "static_leases" {
  for_each = var.enable_dhcp ? var.static_dhcp_leases : {}

  comment     = "Static lease for ${each.key}"
  address     = each.value.ip_address
  mac_address = each.value.mac_address
  server      = var.enable_dhcp ? routeros_ip_dhcp_server.this[0].name : null
}