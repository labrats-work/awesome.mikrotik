# Firewall Module

This module manages RouterOS firewall rules with consistent naming, prioritization, and security controls.

## Features

- **Rule Set Management**:
  - Priority-based rule organization
  - Automatic rule ordering
  - Consistent naming and structure

- **Address List Management**:
  - Standard network classifications
  - Bogon network filtering
  - Service-specific address lists

- **Security Zone Implementation**:
  - Zone-based security model
  - Default policy controls
  - Traffic isolation between zones

## Usage Examples

### Basic Usage

```hcl
module "firewall" {
  source        = "./modules/firewall"
  wan_interface = "ether1"
  
  # Define rule sets
  rule_sets = [
    {
      name     = "global-rules"
      priority = 10
      rules = [
        {
          chain            = "input"
          action           = "accept"
          connection_state = "established,related"
          comment          = "Allow established connections"
          module_name      = "SYSTEM"
        },
        {
          chain       = "input"
          action      = "accept"
          protocol    = "icmp"
          comment     = "Allow ICMP"
          module_name = "SYSTEM"
        }
      ]
    }
  ]
}
```

### Custom Address Lists

```hcl
module "firewall" {
  source        = "./modules/firewall"
  wan_interface = "ether1"
  
  # Custom address lists
  custom_lists = [
    {
      name      = "webapp_servers"
      addresses = ["10.0.20.10", "10.0.20.11"]
      comment   = "Web application servers"
    },
    {
      name      = "trusted_admin_ips"
      addresses = ["192.168.1.100", "10.0.10.5"]
      comment   = "Admin workstations"
    }
  ]
  
  # Rule sets referencing custom lists
  rule_sets = [
    {
      name     = "admin-access"
      priority = 20
      rules = [
        {
          chain            = "input"
          action           = "accept"
          src_address_list = "trusted_admin_ips"
          dst_port         = "22"
          protocol         = "tcp"
          comment          = "Allow SSH from admin IPs"
          module_name      = "ADMIN"
        }
      ]
    }
  ]
}
```

### Advanced Rule Sets with NAT

```hcl
module "firewall" {
  source        = "./modules/firewall"
  wan_interface = "ether1"
  
  rule_sets = [
    # Basic security rules
    {
      name     = "security"
      priority = 10
      rules = [
        {
          chain            = "forward"
          action           = "drop"
          connection_state = "invalid"
          comment          = "Drop invalid connections"
          log              = true
          log_prefix       = "INVALID:"
          module_name      = "SECURITY"
        }
      ]
    },
    
    # NAT rules
    {
      name     = "nat-rules"
      priority = 100
      rules = [
        {
          chain         = "srcnat"
          action        = "masquerade"
          out_interface = "ether1"
          src_address   = "10.0.0.0/8"
          comment       = "Masquerade internal networks"
          module_name   = "NAT"
        },
        {
          chain         = "dstnat"
          action        = "dst-nat"
          protocol      = "tcp"
          dst_port      = "443"
          in_interface  = "ether1"
          to_addresses  = "10.0.20.10"
          to_ports      = "443"
          comment       = "Forward HTTPS to internal server"
          module_name   = "NAT"
        }
      ]
    }
  ]
}
```

## Required Inputs

| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| wan_interface | Name of the WAN interface | string | yes |
| rule_sets | List of rule sets to create | list(object) | yes |

## Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| enable_logging | Enable logging for firewall rules | bool | `true` |
| log_prefix | Prefix for firewall log entries | string | `"FIREWALL:"` |
| enable_global_nat | Enable global NAT masquerade | bool | `true` |
| ensure_default_drops | Ensure default drop rules exist | bool | `true` |
| custom_lists | Custom address lists to create | list(object) | `[]` |
| enable_bogon_blocking | Block traffic from bogon networks | bool | `true` |
| security_zones | Security zones to create | list(object) | *default zones* |

## Outputs

| Name | Description |
|------|-------------|
| address_lists | Names of the created address lists |

## Rule Set Structure

Each rule set follows this structure:

```hcl
{
  name     = "rule-set-name"  # Descriptive name for the rule set
  priority = 50               # Priority (lower = higher priority)
  rules    = [                # List of rules in this set
    {
      chain       = "forward" # RouterOS chain (input, forward, etc.)
      action      = "accept"  # Rule action (accept, drop, etc.)
      
      # Other rule properties as needed
      src_address = "10.0.0.0/24"
      dst_address = "10.0.1.0/24"
      protocol    = "tcp"
      dst_port    = "80,443"
      
      # Metadata for the rule
      comment     = "Allow web traffic between networks"
      module_name = "EXAMPLE" # Used in the rule comment
      log         = true      # Whether to log this rule
      log_prefix  = "WEB:"    # Prefix for log entries
    }
  ]
}
```

## Best Practices

1. **Rule Organization**: Group related rules in the same rule set with appropriate priority
2. **Use Address Lists**: Use address lists instead of hardcoded IPs where possible
3. **Be Specific**: Limit rules to specific protocols and ports needed
4. **Logging Strategy**: Enable logging only for security-significant events
5. **Default Policy**: Always implement default drop rules at the end
6. **Comment All Rules**: Use descriptive comments with zone and purpose information
7. **Rule Order**: Organize rules from most specific to least specific
8. **Regular Audits**: Regularly review all rules for necessity and security