package test

import (
	"testing"
)

// TestVLANModuleStructure verifies the VLAN module has required files, variables, and outputs
func TestVLANModuleStructure(t *testing.T) {
	config := ModuleTestConfig{
		ModuleName:    "vlan",
		ModulePath:    "../terraform/modules/vlan",
		RequiredFiles: []string{"main.tf", "variables.tf", "outputs.tf", "dhcp.tf", "firewall.tf"},
		RequiredVars: []string{
			"vlan_id", "bridge_name", "vlan_cidr", "gateway_ip",
			"interface_lists", "dns_domain", "wan_interface",
		},
		RequiredOutputs: []string{
			"vlan_name", "vlan_id", "network_cidr", "gateway_ip", "firewall_rule_sets",
		},
	}

	TestModuleStructure(t, config)
}

// TestVLANModuleSyntax validates the Terraform syntax of the VLAN module
func TestVLANModuleSyntax(t *testing.T) {
	config := ModuleTestConfig{
		ModuleName: "vlan",
		ModulePath: "../terraform/modules/vlan",
	}

	TestModuleSyntax(t, config)
}

// TestVLANModulePlan checks if a terraform plan with the VLAN module generates the expected resources
func TestVLANModulePlan(t *testing.T) {
	config := ModuleTestConfig{
		ModuleName: "vlan",
		ModulePath: "../terraform/modules/vlan",
		TestVars: map[string]string{
			"vlan_id":         "999",
			"bridge_name":     `"bridge0"`,
			"vlan_cidr":       `"10.99.9.0/24"`,
			"gateway_ip":      `"10.99.9.1"`,
			"interface_lists": `["vlans"]`,
			"dns_domain":      `"test.example.com"`,
			"wan_interface":   `"ether1"`,
			"security_zone":   `"internal"`,
			"disabled":        "true",
		},
		ExpectedResources: []string{
			"routeros_interface_vlan",
			"routeros_ip_address",
			"vlan_id\\s*=\\s*999",
			"name\\s*=\\s*\"vlan999\"",
		},
		RequiredOutputs: []string{
			"vlan_name", "vlan_id", "network_cidr", "gateway_ip",
		},
	}

	TestModulePlan(t, config)
}

func TestVLANModuleApply(t *testing.T) {
	config := ModuleTestConfig{
		ModuleName: "vlan",
		ModulePath: "../terraform/modules/vlan",
		TestVars: map[string]string{
			"vlan_id":         "999",
			"bridge_name":     `"bridge0"`,
			"vlan_cidr":       `"10.99.9.0/24"`,
			"gateway_ip":      `"10.99.9.1"`,
			"interface_lists": `["vlans"]`,
			"dns_domain":      `"test.example.com"`,
			"wan_interface":   `"ether1"`,
			"security_zone":   `"internal"`,
			"disabled":        "true",
		},
		RequiredOutputs: []string{
			"vlan_name", "vlan_id", "network_cidr", "gateway_ip",
		},
	}

	TestModuleApply(t, config)
}
