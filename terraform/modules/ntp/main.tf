# modules/ntp/main.tf
resource "routeros_system_ntp_client" "this" {
  enabled = true
  servers = var.ntp_servers
}

resource "routeros_system_clock" "this" {
  time_zone_name = var.timezone
}