# NTP Module

This module configures RouterOS NTP client settings for accurate time synchronization.

## Features

- **NTP Server Configuration**:
  - Multiple server support
  - Fallback server configuration

- **Timezone Settings**:
  - Configurable timezone

## Usage Examples

### Basic Configuration

```hcl
module "ntp" {
  source      = "./modules/ntp"
  ntp_servers = ["pool.ntp.org", "time.google.com"]
  timezone    = "UTC"
}
```

### Regional Configuration

```hcl
module "ntp" {
  source      = "./modules/ntp"
  ntp_servers = ["europe.pool.ntp.org", "time.cloudflare.com"]
  timezone    = "Europe/Warsaw"
}
```

### Custom NTP Configuration

```hcl
module "ntp" {
  source      = "./modules/ntp"
  ntp_servers = ["10.0.10.100", "10.0.11.100", "time.google.com"]
  timezone    = "America/New_York"
}
```

## Required Inputs

No required inputs. All inputs have default values.

## Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| ntp_servers | List of NTP server addresses | list(string) | `["pool.ntp.org", "time.google.com"]` |
| timezone | System timezone | string | `"UTC"` |

## Outputs

| Name | Description |
|------|-------------|
| ntp_servers | Configured NTP servers |
| timezone | Configured timezone |

## Best Practices

1. **Use Multiple Servers**: Configure at least 3 NTP servers for redundancy
2. **Public Pools**: Use public NTP pools (pool.ntp.org) for reliable service
3. **Regional Servers**: Use geographically close servers when possible
4. **Verify Time**: Regularly verify system time accuracy
5. **Consistent Timezone**: Use the same timezone across network devices
6. **Firewall Rules**: Ensure appropriate firewall rules allow NTP traffic (UDP port 123)

## Integration

This module works well with:

- VLAN module for providing NTP server information via DHCP
- Firewall module for NTP traffic control