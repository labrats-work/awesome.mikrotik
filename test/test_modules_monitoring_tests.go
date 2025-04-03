package test

import (
	"testing"
)

// TestMonitoringModuleInterface validates the Monitoring module interface
// to ensure backward compatibility when making changes to the module
func TestMonitoringModuleInterface(t *testing.T) {
	// Define the expected interface elements
	expectedInterface := ModuleInterface{
		RequiredInputs: []string{
			// Monitoring module has no required inputs
		},
		OptionalInputs: []string{
			"snmp_community",
			"snmp_contact",
			"snmp_location",
			"allowed_networks",
		},
		Outputs: []string{
			"snmp_enabled",
			"snmp_community",
		},
	}

	// Validate module interface
	ValidateModuleInterface(t, "monitoring", expectedInterface)
}
