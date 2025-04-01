# modules/dns/outputs.tf
output "dns_servers" {
  description = "Configured upstream DNS servers"
  value       = routeros_ip_dns.this.servers
}

output "cache_size" {
  description = "DNS cache size"
  value       = routeros_ip_dns.this.cache_size
}