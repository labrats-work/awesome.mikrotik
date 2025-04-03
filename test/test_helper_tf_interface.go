package test

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"testing"
)

// ModuleInterface defines the expected module inputs and outputs
type ModuleInterface struct {
	RequiredInputs []string // Inputs that must be present and don't have defaults
	OptionalInputs []string // Inputs that must be present and have defaults
	Outputs        []string // Expected module outputs
}

// ValidateModuleInterface checks if a module's variables and outputs match expected interface
func ValidateModuleInterface(t *testing.T, moduleName string, expectedInterface ModuleInterface) {
	t.Helper()

	// Get module path
	modulePath := filepath.Join("..", "terraform", "modules", moduleName)
	if customPath := os.Getenv(fmt.Sprintf("%s_MODULE_PATH", strings.ToUpper(moduleName))); customPath != "" {
		modulePath = customPath
	}

	// Check if the module directory exists
	if _, err := os.Stat(modulePath); os.IsNotExist(err) {
		t.Fatalf("Module directory does not exist: %s", modulePath)
	}

	// Sort all string slices for consistent error reporting
	sort.Strings(expectedInterface.RequiredInputs)
	sort.Strings(expectedInterface.OptionalInputs)
	sort.Strings(expectedInterface.Outputs)

	// Validate variables.tf
	validateVariables(t, modulePath, expectedInterface.RequiredInputs, expectedInterface.OptionalInputs)

	// Validate outputs.tf
	validateOutputs(t, modulePath, expectedInterface.Outputs)
}

// validateVariables checks if the variables.tf file contains the expected inputs
func validateVariables(t *testing.T, modulePath string, requiredInputs, optionalInputs []string) {
	t.Helper()

	variablesFile := filepath.Join(modulePath, "variables.tf")

	// Check if variables.tf exists
	if _, err := os.Stat(variablesFile); os.IsNotExist(err) {
		t.Fatalf("variables.tf not found in module directory: %s", modulePath)
	}

	// Read variables.tf content
	variablesContent, err := os.ReadFile(variablesFile)
	if err != nil {
		t.Fatalf("Could not read variables.tf: %v", err)
	}

	variablesStr := string(variablesContent)

	// Find all variable declarations
	varPattern := regexp.MustCompile(`variable\s+"([^"]+)"\s+{([^}]+)}`)
	matches := varPattern.FindAllStringSubmatch(variablesStr, -1)

	// Extract variable names and check for defaults
	foundVars := make(map[string]bool)
	varsWithDefaults := make(map[string]bool)

	for _, match := range matches {
		if len(match) >= 3 {
			varName := match[1]
			varBody := match[2]

			foundVars[varName] = true

			// Check if it has a default value declaration
			// This regex pattern handles various default value formats:
			// 1. Simple defaults (strings, numbers)
			// 2. Empty arrays and maps: default = [] or default = {}
			// 3. Multi-line complex defaults with brackets
			defaultPattern := regexp.MustCompile(`default\s*=\s*(?:(\[\]|\{\})|(\[[\s\S]*?\]|\{[\s\S]*?\})|([^}\n]+))`)
			defaultMatch := defaultPattern.FindStringSubmatch(varBody)

			if defaultMatch != nil {
				varsWithDefaults[varName] = true
			}
		}
	}

	// Validate required inputs
	for _, input := range requiredInputs {
		if !foundVars[input] {
			t.Errorf("Required input not found: %s", input)
		}

		if varsWithDefaults[input] {
			t.Errorf("Required input should not have default value: %s", input)
		}
	}

	// Validate optional inputs
	for _, input := range optionalInputs {
		if !foundVars[input] {
			t.Errorf("Optional input not found: %s", input)
		}

		if !varsWithDefaults[input] {
			t.Errorf("Optional input should have default value: %s", input)
		}
	}

	// Check for undocumented inputs
	var undocumentedInputs []string
	for varName := range foundVars {
		isRequired := false
		isOptional := false

		for _, name := range requiredInputs {
			if name == varName {
				isRequired = true
				break
			}
		}

		if !isRequired {
			for _, name := range optionalInputs {
				if name == varName {
					isOptional = true
					break
				}
			}
		}

		if !isRequired && !isOptional {
			undocumentedInputs = append(undocumentedInputs, varName)
		}
	}

	// Report any undocumented inputs
	if len(undocumentedInputs) > 0 {
		sort.Strings(undocumentedInputs)
		t.Logf("Undocumented inputs found: %s", strings.Join(undocumentedInputs, ", "))
	}
}

// validateOutputs checks if the outputs.tf file contains the expected outputs
func validateOutputs(t *testing.T, modulePath string, expectedOutputs []string) {
	t.Helper()

	outputsFile := filepath.Join(modulePath, "outputs.tf")

	// Check if outputs.tf exists
	if _, err := os.Stat(outputsFile); os.IsNotExist(err) {
		t.Fatalf("outputs.tf not found in module directory: %s", modulePath)
	}

	// Read outputs.tf content
	outputsContent, err := os.ReadFile(outputsFile)
	if err != nil {
		t.Fatalf("Could not read outputs.tf: %v", err)
	}

	outputsStr := string(outputsContent)

	// Find all output declarations
	outputPattern := regexp.MustCompile(`output\s+"([^"]+)"\s+{`)
	matches := outputPattern.FindAllStringSubmatch(outputsStr, -1)

	// Extract output names
	foundOutputs := make(map[string]bool)
	for _, match := range matches {
		if len(match) >= 2 {
			outputName := match[1]
			foundOutputs[outputName] = true
		}
	}

	// Validate expected outputs
	for _, output := range expectedOutputs {
		if !foundOutputs[output] {
			t.Errorf("Output not found: %s", output)
		}
	}

	// Check for undocumented outputs
	var undocumentedOutputs []string
	for outputName := range foundOutputs {
		isExpected := false
		for _, name := range expectedOutputs {
			if name == outputName {
				isExpected = true
				break
			}
		}

		if !isExpected {
			undocumentedOutputs = append(undocumentedOutputs, outputName)
		}
	}

	// Report any undocumented outputs
	if len(undocumentedOutputs) > 0 {
		sort.Strings(undocumentedOutputs)
		t.Logf("Undocumented outputs found: %s", strings.Join(undocumentedOutputs, ", "))
	}
}
