# modules/vlan/firewall.tf

locals {
  # Define firewall rule sets based on VLAN configuration

  # NAT rules for this VLAN (if not using global NAT)
  nat_rules = var.internet_access && !var.use_global_nat ? [{
    chain         = "srcnat"
    action        = "masquerade"
    src_address   = var.vlan_cidr
    out_interface = var.wan_interface
    comment       = "Internet access NAT"
    log           = var.log_firewall
    module_name   = local.vlan_name
  }] : []

  # Allowed services rules (higher priority)
  allowed_services_rules = flatten([
    # DNS rules
    var.allow_dns ? [
      {
        chain       = "input"
        action      = "accept"
        src_address = var.vlan_cidr
        dst_address = var.gateway_ip
        dst_port    = "53"
        protocol    = "tcp"
        comment     = "Allow DNS TCP to Router"
        module_name = local.vlan_name
      },
      {
        chain       = "input"
        action      = "accept"
        src_address = var.vlan_cidr
        dst_address = var.gateway_ip
        dst_port    = "53"
        protocol    = "udp"
        comment     = "Allow DNS UDP to Router"
        module_name = local.vlan_name
      }
    ] : [],

    # NTP rules
    var.allow_ntp ? [
      {
        chain       = "input"
        action      = "accept"
        src_address = var.vlan_cidr
        dst_address = var.gateway_ip
        dst_port    = "123"
        protocol    = "udp"
        comment     = "Allow NTP to Router"
        module_name = local.vlan_name
      }
    ] : [],

    # DHCP rules
    var.enable_dhcp ? [
      {
        chain       = "input"
        action      = "accept"
        src_address = var.vlan_cidr
        dst_address = var.gateway_ip
        dst_port    = "67-68"
        protocol    = "udp"
        comment     = "Allow DHCP to Router"
        module_name = local.vlan_name
      }
    ] : []
  ])

  # Permitted traffic exceptions 
  permitted_traffic_rules = [
    for rule in var.permitted_traffic : {
      chain       = "forward"
      action      = "accept"
      src_address = var.vlan_cidr
      dst_address = rule.destination
      protocol    = rule.protocol
      dst_port    = rule.port
      comment     = "Allow ${rule.protocol}:${rule.port} to ${rule.destination}"
      log         = var.log_firewall
      log_prefix  = var.log_prefix != "" ? var.log_prefix : "${local.vlan_name}:"
      module_name = local.vlan_name
    }
  ]

  # Isolation rules 
  isolation_rules = var.isolate_vlan ? [{
    chain            = "forward"
    action           = "drop"
    src_address      = var.vlan_cidr
    dst_address_list = "vlan_networks"
    comment          = "Isolate from other VLANs"
    log              = var.log_firewall
    log_prefix       = var.log_prefix != "" ? var.log_prefix : "${local.vlan_name}:"
    module_name      = local.vlan_name
  }] : []

  # Custom rules
  custom_rules = [
    for rule in var.custom_firewall_rules : {
      chain       = rule.chain
      action      = rule.action
      src_address = rule.src_address
      dst_address = rule.dst_address
      protocol    = rule.protocol
      dst_port    = rule.dst_port
      src_port    = rule.src_port
      comment     = rule.comment != null ? rule.comment : "Custom rule"
      log         = var.log_firewall
      log_prefix  = var.log_prefix != "" ? var.log_prefix : "${local.vlan_name}:"
      module_name = local.vlan_name
    }
  ]

  # Assemble all rule sets
  firewall_rule_sets = [
    # Services ruleset - always created for allowed services
    length(local.allowed_services_rules) > 0 ? {
      name     = "${local.vlan_name}-services"
      priority = var.security_zone == "management" ? 35 : (var.security_zone == "dmz" ? 45 : 40)
      rules    = local.allowed_services_rules
    } : null,

    # Permitted traffic exceptions
    length(local.permitted_traffic_rules) > 0 ? {
      name     = "${local.vlan_name}-permitted"
      priority = var.security_zone == "management" ? 40 : (var.security_zone == "dmz" ? 60 : 50)
      rules    = local.permitted_traffic_rules
    } : null,

    # Custom rules
    length(local.custom_rules) > 0 ? {
      name     = "${local.vlan_name}-custom"
      priority = var.security_zone == "management" ? 45 : (var.security_zone == "dmz" ? 65 : 55)
      rules    = local.custom_rules
    } : null,

    # Isolation rules
    length(local.isolation_rules) > 0 ? {
      name     = "${local.vlan_name}-isolation"
      priority = var.security_zone == "management" ? 70 : (var.security_zone == "dmz" ? 90 : 80)
      rules    = local.isolation_rules
    } : null,

    # NAT rules
    length(local.nat_rules) > 0 ? {
      name     = "${local.vlan_name}-nat"
      priority = 200
      rules    = local.nat_rules
    } : null
  ]
}