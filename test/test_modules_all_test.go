package test

import (
	"os"
	"strings"
	"testing"
)

// TestAllModuleInterfaces runs interface tests for all modules or a specific module
func TestAllModuleInterfaces(t *testing.T) {
	// Get module to test from environment variable (default to testing all)
	moduleToTest := strings.ToLower(os.Getenv("TEST_MODULE"))

	// Define all available modules
	modules := []string{
		"vlan",
		"firewall",
		"dns",
		"ntp",
		"backup",
		"monitoring",
	}

	// If a specific module is specified, only test that one
	if moduleToTest != "" && moduleToTest != "all" {
		found := false
		for _, module := range modules {
			if module == moduleToTest {
				found = true
				break
			}
		}

		if !found {
			t.Fatalf("Module '%s' not found. Available modules: %s",
				moduleToTest, strings.Join(modules, ", "))
		}

		modules = []string{moduleToTest}
	}

	// Run tests for each module
	for _, module := range modules {
		t.Run(module, func(t *testing.T) {
			switch module {
			case "vlan":
				TestVLANModuleInterface(t)
			case "firewall":
				TestFirewallModuleInterface(t)
			case "dns":
				TestDNSModuleInterface(t)
			case "ntp":
				TestNTPModuleInterface(t)
			case "backup":
				TestBackupModuleInterface(t)
			case "monitoring":
				TestMonitoringModuleInterface(t)
			}
		})
	}
}
