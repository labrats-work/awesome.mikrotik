# DNS Module

This module configures RouterOS DNS settings for central name resolution in the network.

## Features

- **Upstream DNS Configuration**:
  - Configurable DNS servers
  - Flexible provider selection

- **Performance Optimization**:
  - Controllable cache size
  - Local resolution speed

- **Security Controls**:
  - Remote request restrictions
  - Access control

## Usage Examples

### Basic Configuration

```hcl
module "dns" {
  source              = "./modules/dns"
  upstream_dns_servers = ["1.1.1.1", "8.8.8.8"]
  allow_remote_requests = false
  cache_size          = 2048
}
```

### Public DNS Server

```hcl
module "dns" {
  source                = "./modules/dns"
  upstream_dns_servers  = ["9.9.9.9", "149.112.112.112"] # Quad9 DNS
  allow_remote_requests = true
  cache_size            = 4096
}
```

### Local DNS Only

```hcl
module "dns" {
  source                = "./modules/dns"
  upstream_dns_servers  = []  # No upstream servers
  allow_remote_requests = false
  cache_size            = 1024
}
```

## Required Inputs

No required inputs. All inputs have default values.

## Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| upstream_dns_servers | List of upstream DNS servers | list(string) | `["1.1.1.1", "8.8.8.8"]` |
| allow_remote_requests | Allow DNS requests from remote networks | bool | `false` |
| cache_size | Size of DNS cache in KiB | number | `2048` |

## Outputs

| Name | Description |
|------|-------------|
| dns_servers | Configured upstream DNS servers |
| cache_size | DNS cache size |

## Best Practices

1. **Use Reliable Upstream DNS**: Choose reliable DNS providers that respect privacy
2. **Optimize Cache Size**: Adjust cache size based on network size and query volume
3. **Security First**: Only enable remote requests if needed, and control access
4. **Redundancy**: Configure at least two upstream DNS servers for redundancy
5. **Consider Privacy**: Use DNS providers that don't log or track queries where privacy is a concern
6. **Performance**: Use geographically close DNS servers for better performance
7. **Documentation**: Document DNS configuration for network troubleshooting

## Integration

This module works well with:

- VLAN module for DHCP-based DNS configuration
- Firewall module for DNS traffic control