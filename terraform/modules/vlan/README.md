# RouterOS VLAN Module

A comprehensive, testable Terraform module for configuring VLANs on RouterOS devices.

## Features

- **Explicit Network Configuration**:
  - Fully parameterized VLAN creation
  - Direct control over CIDR ranges, gateway IPs and DHCP ranges
  - Support for multiple subnets on the same VLAN

- **Network Services**:
  - Optional DHCP server with customizable IP ranges
  - Configurable DNS domain settings
  - Bridge VLAN configuration with tagged/untagged interfaces

- **Security Controls**:
  - VLAN isolation through firewall rules
  - Granular traffic permissions between VLANs
  - Internet access controls
  - Support for custom firewall rules

- **Testing Support**:
  - Validation through automated tests
  - Testing harness for module verification
  - Mock and real-device testing options

## Usage

```hcl
module "vlan20" {
  source          = "./modules/vlan"
  vlan_id         = 20
  bridge_name     = "bridge0"
  vlan_cidr       = "10.0.20.0/24"
  gateway_ip      = "10.0.20.1"
  interface_lists = ["vlans"]
  
  tagged_interfaces = ["sfp-sfpplus1", "sfp-sfpplus2"]
  dns_domain        = "prod.example.com"
  wan_interface     = "ether1"
  
  # Optional security settings
  security_zone     = "internal"
  isolate_vlan      = true
  log_firewall      = true
  log_prefix        = "PROD-VLAN20:"
}
```

## Required Inputs

| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| vlan_id | VLAN ID number (1-4094) | number | yes |
| bridge_name | Name of the bridge interface | string | yes |
| vlan_cidr | Network CIDR for this VLAN | string | yes |
| gateway_ip | IP address for the VLAN interface | string | yes |
| interface_lists | Interface lists to add VLAN to | list(string) | yes |
| dns_domain | DNS domain for DHCP clients | string | yes |
| wan_interface | WAN interface for NAT | string | yes |

## Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| untagged_interfaces | Interfaces with untagged traffic | list(string) | `[]` |
| tagged_interfaces | Interfaces with tagged traffic | list(string) | `[]` |
| isolate_vlan | Whether to isolate this VLAN | bool | `true` |
| internet_access | Whether to enable internet access | bool | `true` |
| enable_dhcp | Whether to enable DHCP server | bool | `true` |
| dhcp_range_start | Start IP for DHCP range | string | `null` |
| dhcp_range_end | End IP for DHCP range | string | `null` |
| dhcp_lease_time | DHCP lease time | string | `"8h"` |
| permitted_traffic | Permitted traffic exceptions | list(object) | `[]` |
| custom_firewall_rules | Custom firewall rules | list(object) | `[]` |
| security_zone | Security zone for this VLAN | string | `"internal"` |
| log_firewall | Whether to log VLAN firewall rules | bool | `false` |
| log_prefix | Prefix for VLAN firewall log entries | string | `""` |

See [variables.tf](variables.tf) for complete details on all available variables and their descriptions.

## Outputs

| Name | Description |
|------|-------------|
| vlan_name | Name of the created VLAN interface |
| vlan_id | ID of the VLAN |
| network_cidr | Network CIDR block assigned to the VLAN |
| gateway_ip | IP address of the VLAN interface (gateway) |
| dhcp_range | DHCP address range for this VLAN (if enabled) |
| domain | DNS domain name for this VLAN |
| firewall_rule_sets | Firewall rule sets needed for this VLAN |

## Advanced Usage Examples

### Custom DHCP Configuration

```hcl
module "custom_dhcp_vlan" {
  source            = "./modules/vlan"
  vlan_id           = 30
  bridge_name       = "bridge0"
  vlan_cidr         = "192.168.30.0/24"
  gateway_ip        = "192.168.30.254"
  interface_lists   = ["vlans"]
  dns_domain        = "servers.example.com"
  wan_interface     = "ether1"
  
  # DHCP settings
  enable_dhcp       = true
  dhcp_range_start  = "192.168.30.100"
  dhcp_range_end    = "192.168.30.200"
  dhcp_lease_time   = "12h"
  dhcp_dns_servers  = ["192.168.30.254", "1.1.1.1"]
}
```

### Security Configuration

```hcl
module "secure_vlan" {
  source            = "./modules/vlan"
  vlan_id           = 40
  bridge_name       = "bridge0"
  vlan_cidr         = "10.40.0.0/24"
  gateway_ip        = "10.40.0.1"
  interface_lists   = ["vlans"]
  dns_domain        = "dmz.example.com"
  wan_interface     = "ether1"
  
  # Security settings
  security_zone     = "dmz"
  isolate_vlan      = true
  internet_access   = false
  log_firewall      = true
  log_prefix        = "DMZ-40:"
  
  # Permitted traffic exceptions
  permitted_traffic = [
    {
      destination = "10.0.20.0/24"
      protocol    = "tcp"
      port        = "443"
    }
  ]
}
```

## Testing

This module includes a comprehensive testing framework to validate its functionality:

### Running Tests

```bash
# Run basic module syntax and structure tests
./run_test.sh

# Test with a real RouterOS device
USE_REAL_ROUTER=true MIKROTIK_HOST=router.example.com MIKROTIK_USER=admin MIKROTIK_PASSWORD=password ./run_test.sh
```

### Test Environment Variables

- `USE_REAL_ROUTER`: Set to "true" to run tests with a real RouterOS device
- `ENABLE_APPLY`: Set to "true" to actually apply changes during testing (resources are disabled by default)
- `MIKROTIK_HOST`, `MIKROTIK_USER`, `MIKROTIK_PASSWORD`: RouterOS credentials for testing

## Best Practices

1. **Plan Your Network**: Document your VLAN structure and IP allocation before implementation
2. **Use Consistent Naming**: Follow a consistent pattern for VLAN IDs, subnets and DNS domains
3. **Test Changes in Development**: Validate changes in a test environment before production
4. **Document Completions**: Keep a record of all VLAN configurations for reference
5. **Review Firewall Rules**: Regularly review permitted traffic and custom rules
6. **Security First**: Start with more restrictions and relax them as needed rather than the other way around

## License

MIT