# modules/firewall/main.tf
terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
    }
  }
}

# Create base address lists that are always needed
resource "routeros_ip_firewall_addr_list" "base_networks" {
  for_each = {
    "10.0.0.0/8"      = { list = "private_networks", comment = "Private Class A Network" }
    "172.16.0.0/12"   = { list = "private_networks", comment = "Private Class B Network" }
    "192.168.0.0/16"  = { list = "private_networks", comment = "Private Class C Network" }
    "0.0.0.0/8"       = { list = "bogon_networks", comment = "This network" }
    "127.0.0.0/8"     = { list = "bogon_networks", comment = "Loopback" }
    "169.254.0.0/16"  = { list = "bogon_networks", comment = "Link Local" }
    "192.0.0.0/24"    = { list = "bogon_networks", comment = "IETF Protocol Assignments" }
    "192.0.2.0/24"    = { list = "bogon_networks", comment = "TEST-NET-1" }
    "198.51.100.0/24" = { list = "bogon_networks", comment = "TEST-NET-2" }
    "203.0.113.0/24"  = { list = "bogon_networks", comment = "TEST-NET-3" }
    "224.0.0.0/4"     = { list = "bogon_networks", comment = "Multicast" }
    "240.0.0.0/4"     = { list = "bogon_networks", comment = "Reserved" }
  }

  address = each.key
  list    = each.value.list
  comment = each.value.comment
}

# Create service-specific address lists
resource "routeros_ip_firewall_addr_list" "service_networks" {
  for_each = {
    "1.1.1.1"             = { list = "dns_servers", comment = "Cloudflare DNS 1" }
    "1.0.0.1"             = { list = "dns_servers", comment = "Cloudflare DNS 2" }
    "8.8.8.8"             = { list = "dns_servers", comment = "Google DNS 1" }
    "8.8.4.4"             = { list = "dns_servers", comment = "Google DNS 2" }
    "9.9.9.9"             = { list = "dns_servers", comment = "Quad9 DNS" }
    "149.112.112.112"     = { list = "dns_servers", comment = "Quad9 DNS 2" }
    "pool.ntp.org"        = { list = "ntp_servers", comment = "NTP Pool" }
    "time.google.com"     = { list = "ntp_servers", comment = "Google NTP" }
    "time.cloudflare.com" = { list = "ntp_servers", comment = "Cloudflare NTP" }
  }

  address = each.value.list == "ntp_servers" ? each.key : each.key
  list    = each.value.list
  comment = each.value.comment
}

# Manage custom address lists and entries
resource "routeros_ip_firewall_addr_list" "custom_entries" {
  for_each = {
    for entry in flatten([
      for custom_list in var.custom_lists : [
        for addr in custom_list.addresses : {
          list_name = custom_list.name
          address   = addr
          key       = "${custom_list.name}-${addr}"
        }
      ]
    ]) : entry.key => entry
  }

  address = each.value.address
  list    = each.value.list_name
  comment = "Custom entry for ${each.value.list_name}"
}

# Create filter rules from rule sets
resource "routeros_ip_firewall_filter" "rules" {
  for_each = local.filter_rules_map

  # Base properties
  chain  = each.value.chain
  action = each.value.action

  # Conditional properties
  src_address      = lookup(each.value, "src_address", null)
  dst_address      = lookup(each.value, "dst_address", null)
  src_address_list = lookup(each.value, "src_address_list", null)
  dst_address_list = lookup(each.value, "dst_address_list", null)
  protocol         = lookup(each.value, "protocol", null)
  src_port         = lookup(each.value, "src_port", null)
  dst_port         = lookup(each.value, "dst_port", null)
  in_interface     = lookup(each.value, "in_interface", null)
  out_interface    = lookup(each.value, "out_interface", null)
  connection_state = lookup(each.value, "connection_state", null)

  # Standardized comment with priority
  comment    = "${lookup(each.value, "module_name", "SYSTEM")}: ${lookup(each.value, "comment", "Firewall rule")} [priority:${each.value.set_priority}]"
  log        = lookup(each.value, "log", var.enable_logging)
  log_prefix = lookup(each.value, "log_prefix", var.log_prefix)
  disabled   = lookup(each.value, "disabled", false)
}

# Create NAT rules
resource "routeros_ip_firewall_nat" "rules" {
  for_each = local.nat_rules_map

  # Base properties
  chain  = each.value.chain
  action = each.value.action

  # Conditional properties
  src_address   = lookup(each.value, "src_address", null)
  dst_address   = lookup(each.value, "dst_address", null)
  protocol      = lookup(each.value, "protocol", null)
  src_port      = lookup(each.value, "src_port", null)
  dst_port      = lookup(each.value, "dst_port", null)
  in_interface  = lookup(each.value, "in_interface", null)
  out_interface = lookup(each.value, "out_interface", null)
  to_addresses  = lookup(each.value, "to_addresses", null)
  to_ports      = lookup(each.value, "to_ports", null)

  # Standardized comment with priority
  comment  = "${lookup(each.value, "module_name", "SYSTEM")}: ${lookup(each.value, "comment", "NAT rule")} [priority:${each.value.set_priority}]"
  log      = lookup(each.value, "log", var.enable_logging)
  disabled = lookup(each.value, "disabled", false)
}

# Order the input chain rules
resource "routeros_move_items" "input_chain_ordering" {
  count         = length(local.input_chain_sequence) > 0 ? 1 : 0
  resource_path = "/ip/firewall/filter"
  sequence      = local.input_chain_sequence
  depends_on    = [routeros_ip_firewall_filter.rules]
}

# Order the forward chain rules
resource "routeros_move_items" "forward_chain_ordering" {
  count         = length(local.forward_chain_sequence) > 0 ? 1 : 0
  resource_path = "/ip/firewall/filter"
  sequence      = local.forward_chain_sequence
  depends_on    = [routeros_ip_firewall_filter.rules, routeros_move_items.input_chain_ordering]
}

# Order the mangle chain rules (if any exist)
resource "routeros_move_items" "mangle_chain_ordering" {
  count         = length(local.mangle_chain_sequence) > 0 ? 1 : 0
  resource_path = "/ip/firewall/filter"
  sequence      = local.mangle_chain_sequence
  depends_on    = [routeros_ip_firewall_filter.rules, routeros_move_items.forward_chain_ordering]
}

# Order the NAT chain rules
resource "routeros_move_items" "nat_chain_ordering" {
  count         = length(local.nat_chain_sequence) > 0 ? 1 : 0
  resource_path = "/ip/firewall/nat"
  sequence      = local.nat_chain_sequence
  depends_on    = [routeros_ip_firewall_nat.rules, routeros_move_items.mangle_chain_ordering]
}