# modules/vlan/providers.tf

terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
    }
  }
  required_version = ">= 1.0.0"
}