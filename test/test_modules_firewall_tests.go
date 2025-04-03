package test

import (
	"testing"
)

// TestFirewallModuleInterface validates the Firewall module interface
// to ensure backward compatibility when making changes to the module
func TestFirewallModuleInterface(t *testing.T) {
	// Define the expected interface elements
	expectedInterface := ModuleInterface{
		RequiredInputs: []string{
			"wan_interface",
			"rule_sets",
		},
		OptionalInputs: []string{
			"enable_logging",
			"log_prefix",
			"enable_global_nat",
			"ensure_default_drops",
			"custom_lists",
			"enable_bogon_blocking",
			"security_zones",
		},
		Outputs: []string{
			"address_lists",
		},
	}

	// Validate module interface
	ValidateModuleInterface(t, "firewall", expectedInterface)
}
