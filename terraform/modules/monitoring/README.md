# Monitoring Module

This module configures SNMP monitoring for RouterOS devices.

## Features

- **SNMP Configuration**:
  - Community string management
  - Contact and location information

- **Security Controls**:
  - Network access restrictions
  - Community string validation

## Usage Examples

### Basic Configuration

```hcl
module "monitoring" {
  source           = "./modules/monitoring"
  snmp_community   = "public"
  snmp_contact     = "admin@example.com" 
  snmp_location    = "Server Room"
  allowed_networks = []  # No restrictions
}
```

### Secure Configuration

```hcl
module "monitoring" {
  source           = "./modules/monitoring"
  snmp_community   = "SecureMonitorString"
  snmp_contact     = "networking@example.com"
  snmp_location    = "Main Office - Rack 3"
  allowed_networks = ["10.0.10.0/24", "10.0.11.0/24"]  # Only management networks
}
```

### Enterprise Configuration

```hcl
module "monitoring" {
  source           = "./modules/monitoring"
  snmp_community   = "EntMonitor2025"
  snmp_contact     = "noc@enterprise.com"
  snmp_location    = "Data Center 2 - Row 5 - Rack 10"
  allowed_networks = ["10.0.10.5/32", "10.0.10.6/32"]  # Only specific monitoring servers
}
```

## Required Inputs

No required inputs. All inputs have default values.

## Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| snmp_community | SNMP community string | string | `"public"` |
| snmp_contact | Contact information for SNMP | string | `"admin@example.com"` |
| snmp_location | Physical location of the device | string | `"Server Room"` |
| allowed_networks | Networks allowed to query via SNMP | list(string) | `[]` |

## Outputs

| Name | Description |
|------|-------------|
| snmp_enabled | Whether SNMP is enabled |
| snmp_community | SNMP community string (sensitive) |

## Security Considerations

The module implements validation to ensure the SNMP community string is at least 5 characters long for security purposes.

## Best Practices

1. **Strong Community Strings**: Use complex community strings, not default values
2. **Restrict Access**: Limit SNMP access to specific monitoring servers
3. **Regular Updates**: Keep contact information up to date
4. **Detailed Location**: Provide specific location information for physical identification
5. **Upgrade to SNMPv3**: Consider implementing SNMPv3 for stronger security
6. **Monitoring**: Set up alerts for unauthorized SNMP access attempts
7. **Documentation**: Document SNMP configuration for monitoring system setup

## Integration

This module works well with external monitoring systems such as:

- Zabbix
- LibreNMS
- PRTG
- Nagios/Icinga
- Prometheus with SNMP Exporter