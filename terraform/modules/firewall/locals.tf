# modules/firewall/locals.tf

locals {
  # Process and normalize all rule sets
  normalized_rule_sets = [
    for rule_set in var.rule_sets :
    rule_set if rule_set != null
  ]

  # Sort rule sets by priority
  rule_sets_by_priority = {
    for idx, rule_set in local.normalized_rule_sets :
    format("%04d-%02d", rule_set.priority, idx) => rule_set
  }

  # Get sorted rule sets
  sorted_rule_sets = [
    for key in sort(keys(local.rule_sets_by_priority)) :
    local.rule_sets_by_priority[key]
  ]

  # Flatten into a single ordered list of rules with metadata
  all_rules = flatten([
    for set in local.sorted_rule_sets : [
      for idx, rule in set.rules : merge(rule, {
        set_priority = set.priority
        set_name     = set.name
        rule_index   = idx
        unique_id    = "${set.name}-${format("%04d", set.priority)}-${format("%03d", idx)}"
      })
    ]
  ])

  # Create maps for each rule type
  filter_rules_map = {
    for rule in local.all_rules :
    rule.unique_id => rule
    if rule.chain == "input" || rule.chain == "forward" || rule.chain == "mangle"
  }

  nat_rules_map = {
    for rule in local.all_rules :
    rule.unique_id => rule
    if rule.chain == "srcnat" || rule.chain == "dstnat"
  }

  # Split rules by chain for ordering
  input_rules   = [for rule in local.all_rules : rule if rule.chain == "input"]
  forward_rules = [for rule in local.all_rules : rule if rule.chain == "forward"]
  mangle_rules  = [for rule in local.all_rules : rule if rule.chain == "mangle"]
  nat_rules     = [for rule in local.all_rules : rule if rule.chain == "srcnat" || rule.chain == "dstnat"]

  # Create ordered sequence lists for each chain
  input_chain_sequence = [
    for rule in local.input_rules :
    routeros_ip_firewall_filter.rules[rule.unique_id].id
  ]

  forward_chain_sequence = [
    for rule in local.forward_rules :
    routeros_ip_firewall_filter.rules[rule.unique_id].id
  ]

  mangle_chain_sequence = [
    for rule in local.mangle_rules :
    routeros_ip_firewall_filter.rules[rule.unique_id].id
  ]

  nat_chain_sequence = [
    for rule in local.nat_rules :
    routeros_ip_firewall_nat.rules[rule.unique_id].id
  ]

  # Generate default drop rules if requested
  default_drops = var.ensure_default_drops ? [
    {
      chain        = "input"
      action       = "drop"
      comment      = "Default drop rule for input chain"
      log          = true
      log_prefix   = "${var.log_prefix} INPUT DROP"
      module_name  = "FIREWALL"
      set_priority = 9999
      rule_index   = 0
      unique_id    = "default-drop-input-9999-000"
    },
    {
      chain        = "forward"
      action       = "drop"
      comment      = "Default drop rule for forward chain"
      log          = true
      log_prefix   = "${var.log_prefix} FORWARD DROP"
      module_name  = "FIREWALL"
      set_priority = 9999
      rule_index   = 1
      unique_id    = "default-drop-forward-9999-001"
    }
  ] : []
}