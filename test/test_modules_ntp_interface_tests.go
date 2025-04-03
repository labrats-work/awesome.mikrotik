package test

import (
	"testing"
)

// TestNTPModuleInterface validates the NTP module interface
// to ensure backward compatibility when making changes to the module
func TestNTPModuleInterface(t *testing.T) {
	// Define the expected interface elements
	expectedInterface := ModuleInterface{
		RequiredInputs: []string{
			// NTP module has no required inputs
		},
		OptionalInputs: []string{
			"ntp_servers",
			"timezone",
		},
		Outputs: []string{
			"ntp_servers",
			"timezone",
		},
	}

	// Validate module interface
	ValidateModuleInterface(t, "ntp", expectedInterface)
}
