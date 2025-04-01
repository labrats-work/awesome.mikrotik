# modules/vlan/data.tf

# Get bridge interface data
data "routeros_interfaces" "bridge" {
  filter = {
    name = var.bridge_name
  }

  lifecycle {
    postcondition {
      condition     = length(self.interfaces) > 0
      error_message = "Bridge interface '${var.bridge_name}' not found."
    }
  }
}