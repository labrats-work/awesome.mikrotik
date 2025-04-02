package test

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

// ModuleTestConfig holds configuration for module tests
type ModuleTestConfig struct {
	ModuleName        string            // Name of the module to test (e.g., "vlan", "firewall")
	ModulePath        string            // Path to the module directory
	RequiredFiles     []string          // List of required files in the module
	RequiredVars      []string          // List of required variables
	RequiredOutputs   []string          // List of required outputs
	ExpectedResources []string          // Resources expected in terraform plan output
	TestVars          map[string]string // Test variables for the module
}

// GetEnvOrDefault returns environment variable value or default if not set
func GetEnvOrDefault(key, defaultValue string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return defaultValue
}

// TestModuleStructure verifies the module structure:
// required files, variables, and outputs.
func TestModuleStructure(t *testing.T, config ModuleTestConfig) {
	// Check if we should skip this test
	if os.Getenv(fmt.Sprintf("SKIP_%s_STRUCTURE", strings.ToUpper(config.ModuleName))) == "true" {
		t.Skipf("Skipping %s module structure test", config.ModuleName)
	}

	t.Logf("Testing %s module structure", config.ModuleName)

	// Check for required files
	for _, file := range config.RequiredFiles {
		filePath := filepath.Join(config.ModulePath, file)
		if _, err := os.Stat(filePath); os.IsNotExist(err) {
			t.Errorf("Required file missing: %s", file)
		}
	}

	// Check for required variables
	varsFilePath := filepath.Join(config.ModulePath, "variables.tf")
	if _, err := os.Stat(varsFilePath); err == nil {
		varsContent, err := os.ReadFile(varsFilePath)
		if err != nil {
			t.Fatalf("Failed to read variables.tf: %v", err)
		}

		for _, varName := range config.RequiredVars {
			pattern := regexp.MustCompile(fmt.Sprintf(`variable\s+"%s"`, varName))
			if !pattern.Match(varsContent) {
				t.Errorf("Required variable not found: %s", varName)
			}
		}
	} else if len(config.RequiredVars) > 0 {
		t.Errorf("variables.tf file not found, but variables are required")
	}

	// Check for required outputs
	outputsFilePath := filepath.Join(config.ModulePath, "outputs.tf")
	if _, err := os.Stat(outputsFilePath); err == nil {
		outputsContent, err := os.ReadFile(outputsFilePath)
		if err != nil {
			t.Fatalf("Failed to read outputs.tf: %v", err)
		}

		for _, outputName := range config.RequiredOutputs {
			pattern := regexp.MustCompile(fmt.Sprintf(`output\s+"%s"`, outputName))
			if !pattern.Match(outputsContent) {
				t.Errorf("Required output not found: %s", outputName)
			}
		}
	} else if len(config.RequiredOutputs) > 0 {
		t.Errorf("outputs.tf file not found, but outputs are required")
	}
}

// TestModuleSyntax validates the Terraform syntax of the module
func TestModuleSyntax(t *testing.T, config ModuleTestConfig) {
	// Check if we should skip this test
	if os.Getenv(fmt.Sprintf("SKIP_%s_SYNTAX", strings.ToUpper(config.ModuleName))) == "true" {
		t.Skipf("Skipping %s module syntax test", config.ModuleName)
	}

	t.Logf("Testing %s module syntax", config.ModuleName)

	// Skip if module directory doesn't exist
	if _, err := os.Stat(config.ModulePath); os.IsNotExist(err) {
		t.Skipf("Module directory not found: %s", config.ModulePath)
	}

	// Run terraform init -backend=false
	initCmd := exec.Command("terraform", "init", "-backend=false")
	initCmd.Dir = config.ModulePath
	initOutput, err := initCmd.CombinedOutput()

	// Verify initialization succeeded
	if err != nil {
		t.Fatalf("Terraform init failed: %v\nOutput: %s", err, initOutput)
	}

	// Run terraform validate
	validateCmd := exec.Command("terraform", "validate")
	validateCmd.Dir = config.ModulePath
	validateOutput, err := validateCmd.CombinedOutput()

	// Verify validation succeeded
	if err != nil {
		t.Fatalf("Terraform validate failed: %v\nOutput: %s", err, validateOutput)
	}

	// Confirm success message in validation output
	if !strings.Contains(string(validateOutput), "Success!") {
		t.Errorf("Terraform validate did not report success: %s", validateOutput)
	}
}

// TestModulePlan checks if a terraform plan with the module generates
// the expected resources
func TestModulePlan(t *testing.T, config ModuleTestConfig) {
	// Check if we should skip this test
	if os.Getenv(fmt.Sprintf("SKIP_%s_PLAN", strings.ToUpper(config.ModuleName))) == "true" {
		t.Skipf("Skipping %s module plan test", config.ModuleName)
	}

	t.Logf("Testing %s module plan", config.ModuleName)

	// Skip if global SKIP_PLAN is set
	if os.Getenv("SKIP_PLAN") == "true" {
		t.Skip("Skipping plan test due to SKIP_PLAN=true")
	}

	// Create temporary dir for testing
	tmpDir, err := os.MkdirTemp(".", fmt.Sprintf("%s-test-*", config.ModuleName))
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create test configuration content
	var mainTFContent strings.Builder
	mainTFContent.WriteString(`
terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
    }
  }
}

provider "routeros" {
  # Credentials from environment variables
}

module "test_module" {
  source = "`)
	mainTFContent.WriteString(config.ModulePath)
	mainTFContent.WriteString(`"

`)

	// Add module variables
	for key, value := range config.TestVars {
		mainTFContent.WriteString(fmt.Sprintf("  %s = %s\n", key, value))
	}

	mainTFContent.WriteString(`}

# Output all module outputs
`)

	// Add outputs
	for _, output := range config.RequiredOutputs {
		mainTFContent.WriteString(fmt.Sprintf(`output "%s" {
  value = module.test_module.%s
}
`, output, output))
	}

	// Write configuration to file
	mainTFPath := filepath.Join(tmpDir, "main.tf")
	if err := os.WriteFile(mainTFPath, []byte(mainTFContent.String()), 0644); err != nil {
		t.Fatalf("Failed to write main.tf: %v", err)
	}

	// Set environment variables for mock credentials if not testing with real router
	useRealRouter := os.Getenv("USE_REAL_ROUTER") == "true"
	if !useRealRouter {
		os.Setenv("MIKROTIK_HOST", GetEnvOrDefault("MIKROTIK_HOST", "dummy.example.com"))
		os.Setenv("MIKROTIK_USER", GetEnvOrDefault("MIKROTIK_USER", "dummy"))
		os.Setenv("MIKROTIK_PASSWORD", GetEnvOrDefault("MIKROTIK_PASSWORD", "dummy"))
	}

	// Run terraform init
	initCmd := exec.Command("terraform", "init")
	initCmd.Dir = tmpDir
	initOutput, err := initCmd.CombinedOutput()
	if err != nil {
		t.Fatalf("Terraform init failed: %v\nOutput: %s", err, initOutput)
	}

	// Run terraform plan
	planCmd := exec.Command("terraform", "plan", "-no-color")
	planCmd.Dir = tmpDir
	planOutput, err := planCmd.CombinedOutput()
	planOutputStr := string(planOutput)

	// Check plan output with different expectations based on real/mock router
	if useRealRouter && err != nil {
		t.Fatalf("Terraform plan failed with real router: %v\nOutput: %s", err, planOutputStr)
	}

	// Check for expected resources in plan output
	for _, pattern := range config.ExpectedResources {
		re := regexp.MustCompile(pattern)
		if !re.MatchString(planOutputStr) {
			t.Errorf("Expected pattern '%s' not found in plan output", pattern)
		}
	}
}

// TestModuleApply tests applying and destroying a module configuration with a real RouterOS device
func TestModuleApply(t *testing.T, config ModuleTestConfig) {
	// Check if we should skip this test
	if os.Getenv(fmt.Sprintf("SKIP_%s_APPLY", strings.ToUpper(config.ModuleName))) == "true" {
		t.Skipf("Skipping %s module apply test", config.ModuleName)
	}

	t.Logf("Testing %s module apply and destroy", config.ModuleName)

	// Skip if not testing with real router
	if os.Getenv("USE_REAL_ROUTER") != "true" {
		t.Skip("Skipping real router test (USE_REAL_ROUTER != true)")
	}

	// Skip apply/destroy unless explicitly enabled
	if os.Getenv("ENABLE_APPLY") != "true" {
		t.Skip("Skipping apply/destroy test (ENABLE_APPLY != true)")
	}

	// Verify router credentials are set
	host := os.Getenv("MIKROTIK_HOST")
	user := os.Getenv("MIKROTIK_USER")
	pass := os.Getenv("MIKROTIK_PASSWORD")

	if host == "" || user == "" || pass == "" {
		t.Fatal("MIKROTIK_HOST, MIKROTIK_USER and MIKROTIK_PASSWORD must be set for real router tests")
	}

	// Create temporary directory
	tmpDir, err := os.MkdirTemp(".", fmt.Sprintf("%s-real-test-*", config.ModuleName))
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create test configuration content
	var mainTFContent strings.Builder
	mainTFContent.WriteString(`
terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
    }
  }
}

provider "routeros" {
  # Credentials from environment variables
}

module "test_module" {
  source = "`)
	mainTFContent.WriteString(config.ModulePath)
	mainTFContent.WriteString(`"

`)

	// Add module variables
	for key, value := range config.TestVars {
		mainTFContent.WriteString(fmt.Sprintf("  %s = %s\n", key, value))
	}

	mainTFContent.WriteString(`}

# Output all module outputs
`)

	// Add outputs
	for _, output := range config.RequiredOutputs {
		mainTFContent.WriteString(fmt.Sprintf(`output "%s" {
  value = module.test_module.%s
}
`, output, output))
	}

	// Write configuration to file
	mainTFPath := filepath.Join(tmpDir, "main.tf")
	if err := os.WriteFile(mainTFPath, []byte(mainTFContent.String()), 0644); err != nil {
		t.Fatalf("Failed to write main.tf: %v", err)
	}

	// Initialize Terraform
	initCmd := exec.Command("terraform", "init")
	initCmd.Dir = tmpDir
	initOutput, err := initCmd.CombinedOutput()
	if err != nil {
		t.Fatalf("Terraform init failed: %v\nOutput: %s", err, initOutput)
	}

	// Apply configuration
	applyCmd := exec.Command("terraform", "apply", "-auto-approve")
	applyCmd.Dir = tmpDir
	applyOutput, err := applyCmd.CombinedOutput()

	// Verify apply succeeded
	if err != nil {
		t.Fatalf("Terraform apply failed: %v\nOutput: %s", err, applyOutput)
	}

	// Get outputs
	outputCmd := exec.Command("terraform", "output", "-json")
	outputCmd.Dir = tmpDir
	outputJSON, err := outputCmd.CombinedOutput()

	// Check outputs
	if err != nil {
		t.Errorf("Failed to get outputs: %v", err)
	} else {
		// Log the outputs for debugging
		t.Logf("Module outputs: %s", outputJSON)

		// Check required outputs exist in JSON
		for _, output := range config.RequiredOutputs {
			if !strings.Contains(string(outputJSON), fmt.Sprintf(`"%s"`, output)) {
				t.Errorf("Expected output '%s' not found in outputs", output)
			}
		}
	}

	// Destroy resources
	destroyCmd := exec.Command("terraform", "destroy", "-auto-approve")
	destroyCmd.Dir = tmpDir
	destroyOutput, err := destroyCmd.CombinedOutput()

	// Verify destroy succeeded
	if err != nil {
		t.Fatalf("Terraform destroy failed: %v\nOutput: %s", err, destroyOutput)
	}
}
