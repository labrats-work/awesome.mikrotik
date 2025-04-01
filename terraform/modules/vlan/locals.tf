# modules/vlan/locals.tf

locals {
  # VLAN naming
  vlan_name = "vlan${var.vlan_id}"

  # Network calculations
  vlan_network = cidrhost(var.vlan_cidr, 0)

  # DHCP range calculations - use provided values or calculate sane defaults
  dhcp_address_start = var.dhcp_range_start != null ? var.dhcp_range_start : cidrhost(var.vlan_cidr, 10)
  dhcp_address_end   = var.dhcp_range_end != null ? var.dhcp_range_end : cidrhost(var.vlan_cidr, -2)

  # Winbox and SSH rules if enabled
  management_rules = flatten([
    # Winbox rules
    var.allow_winbox ? [
      {
        chain       = "input"
        action      = "accept"
        src_address = var.vlan_cidr
        dst_address = var.gateway_ip
        dst_port    = "8291"
        protocol    = "tcp"
        comment     = "Allow Winbox to Router"
        log         = var.log_firewall
        log_prefix  = var.log_prefix != "" ? var.log_prefix : "${local.vlan_name}:"
        module_name = local.vlan_name
      }
    ] : [],

    # SSH rules
    var.allow_ssh ? [
      {
        chain       = "input"
        action      = "accept"
        src_address = var.vlan_cidr
        dst_address = var.gateway_ip
        dst_port    = "22"
        protocol    = "tcp"
        comment     = "Allow SSH to Router"
        log         = var.log_firewall
        log_prefix  = var.log_prefix != "" ? var.log_prefix : "${local.vlan_name}:"
        module_name = local.vlan_name
      }
    ] : []
  ])
}