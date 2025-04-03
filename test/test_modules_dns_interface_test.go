package test

import (
	"testing"
)

// TestDNSModuleInterface validates the DNS module interface
// to ensure backward compatibility when making changes to the module
func TestDNSModuleInterface(t *testing.T) {
	// Define the expected interface elements
	expectedInterface := ModuleInterface{
		RequiredInputs: []string{
			// DNS module has no required inputs
		},
		OptionalInputs: []string{
			"upstream_dns_servers",
			"allow_remote_requests",
			"cache_size",
		},
		Outputs: []string{
			"dns_servers",
			"cache_size",
		},
	}

	// Validate module interface
	ValidateModuleInterface(t, "dns", expectedInterface)
}
