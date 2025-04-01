output "address_lists" {
  description = "Names of the created address lists"
  value = {
    private_networks = "private_networks"
    bogon_networks   = "bogon_networks"
    dns_servers      = "dns_servers"
    ntp_servers      = "ntp_servers"
    custom_lists     = [for list in var.custom_lists : list.name]
  }
}