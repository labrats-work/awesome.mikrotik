package test

import (
	"testing"
)

// TestBackupModuleInterface validates the Backup module interface
// to ensure backward compatibility when making changes to the module
func TestBackupModuleInterface(t *testing.T) {
	// Define the expected interface elements
	expectedInterface := ModuleInterface{
		RequiredInputs: []string{
			// Backup module has no required inputs
		},
		OptionalInputs: []string{
			"backup_name",
			"backup_password",
			"backup_interval",
		},
		Outputs: []string{
			"backup_schedule",
			"backup_name_pattern",
		},
	}

	// Validate module interface
	ValidateModuleInterface(t, "backup", expectedInterface)
}
