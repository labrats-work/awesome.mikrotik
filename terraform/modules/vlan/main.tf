# modules/vlan/main.tf

# Create VLAN interface
resource "routeros_interface_vlan" "this" {
  name      = local.vlan_name
  comment   = var.description != "" ? var.description : "VLAN ${var.vlan_id} - ${var.dns_domain}"
  interface = data.routeros_interfaces.bridge.interfaces[0].name
  vlan_id   = var.vlan_id
  disabled  = var.disabled
}

# Assign IP address to VLAN interface
resource "routeros_ip_address" "this" {
  address   = "${var.gateway_ip}/${split("/", var.vlan_cidr)[1]}"
  network   = local.vlan_network
  interface = routeros_interface_vlan.this.name
  comment   = "Gateway for ${local.vlan_name}"
  disabled  = var.disabled
}

# Add VLAN interface to specified interface lists
resource "routeros_interface_list_member" "this" {
  for_each  = toset(var.interface_lists)
  comment   = local.vlan_name
  interface = routeros_interface_vlan.this.name
  list      = each.value
}

# Configure bridge VLAN
resource "routeros_interface_bridge_vlan" "this" {
  comment  = local.vlan_name
  bridge   = var.bridge_name
  vlan_ids = [var.vlan_id]
  tagged   = setunion([var.bridge_name], var.tagged_interfaces)
  untagged = var.untagged_interfaces
}

# Add VLAN network to address lists
resource "routeros_ip_firewall_addr_list" "vlan_network" {
  address  = var.vlan_cidr
  comment  = "${local.vlan_name}: VLAN network"
  list     = "vlan_networks"
  disabled = var.disabled
}

resource "routeros_ip_firewall_addr_list" "security_zone" {
  address  = var.vlan_cidr
  comment  = "${local.vlan_name}: ${var.security_zone} zone network"
  list     = "${var.security_zone}_networks"
  disabled = var.disabled
}

# Add to custom address lists if specified
resource "routeros_ip_firewall_addr_list" "additional_lists" {
  for_each = { for idx, al in var.address_lists : "${al.list}-${idx}" => al }
  address  = var.vlan_cidr
  comment  = each.value.comment != null ? "${local.vlan_name}: ${each.value.comment}" : "${local.vlan_name}: Network in list ${each.value.list}"
  list     = each.value.list
  disabled = coalesce(each.value.disabled, var.disabled)
}