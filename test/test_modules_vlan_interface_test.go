package test

import (
	"testing"
)

// TestVLANModuleInterface validates the VLAN module interface (inputs and outputs)
// to ensure backward compatibility when making changes to the module
func TestVLANModuleInterface(t *testing.T) {
	// Define the expected interface elements
	expectedInterface := ModuleInterface{
		RequiredInputs: []string{
			"vlan_id",
			"bridge_name",
			"vlan_cidr",
			"gateway_ip",
			"interface_lists",
			"dns_domain",
			"wan_interface",
		},
		OptionalInputs: []string{
			"description",
			"disabled",
			"untagged_interfaces",
			"tagged_interfaces",
			"enable_dhcp",
			"dhcp_range_start",
			"dhcp_range_end",
			"dhcp_lease_time",
			"dhcp_dns_servers",
			"dhcp_ntp_servers",
			"dhcp_wins_servers",
			"enable_dhcp_dns_update",
			"static_dhcp_leases",
			"address_lists",
			"security_zone",
			"isolate_vlan",
			"internet_access",
			"use_global_nat",
			"permitted_traffic",
			"custom_firewall_rules",
			"log_firewall",
			"log_prefix",
			"allow_dns",
			"allow_ntp",
			"allow_winbox",
			"allow_ssh",
		},
		Outputs: []string{
			"vlan_name",
			"vlan_id",
			"network_cidr",
			"gateway_ip",
			"dhcp_range",
			"domain",
			"security_zone",
			"interface_id",
			"is_management",
			"is_dmz",
			"firewall_rule_sets",
		},
	}

	// Validate module interface
	ValidateModuleInterface(t, "vlan", expectedInterface)
}
