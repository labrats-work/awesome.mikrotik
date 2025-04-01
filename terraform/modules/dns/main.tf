# modules/dns/main.tf
resource "routeros_ip_dns" "this" {
  allow_remote_requests = var.allow_remote_requests
  cache_size            = var.cache_size
  servers               = var.upstream_dns_servers
}