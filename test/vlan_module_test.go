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

// TestVLANModuleStructure verifies the VLAN module structure:
// required files, variables, and outputs.
func TestVLANModuleStructure(t *testing.T) {
	// ARRANGE
	modulePath := "../modules/vlan"
	requiredFiles := []string{"main.tf", "variables.tf", "outputs.tf"}
	requiredVars := []string{"vlan_id", "bridge_name", "vlan_cidr", "gateway_ip", "interface_lists", "wan_interface"}
	requiredOutputs := []string{"vlan_name", "network_cidr", "gateway_ip"}

	// ACT & ASSERT: Check for required files
	for _, file := range requiredFiles {
		filePath := filepath.Join(modulePath, file)
		if _, err := os.Stat(filePath); os.IsNotExist(err) {
			t.Errorf("Required file missing: %s", file)
		}
	}

	// ACT & ASSERT: Check for required variables
	varsContent, err := os.ReadFile(filepath.Join(modulePath, "variables.tf"))
	if err != nil {
		t.Fatalf("Failed to read variables.tf: %v", err)
	}

	for _, varName := range requiredVars {
		pattern := regexp.MustCompile(fmt.Sprintf(`variable\s+"%s"`, varName))
		if !pattern.Match(varsContent) {
			t.Errorf("Required variable not found: %s", varName)
		}
	}

	// ACT & ASSERT: Check for required outputs
	outputsContent, err := os.ReadFile(filepath.Join(modulePath, "outputs.tf"))
	if err != nil {
		t.Fatalf("Failed to read outputs.tf: %v", err)
	}

	for _, outputName := range requiredOutputs {
		pattern := regexp.MustCompile(fmt.Sprintf(`output\s+"%s"`, outputName))
		if !pattern.Match(outputsContent) {
			t.Errorf("Required output not found: %s", outputName)
		}
	}
}

// TestVLANModuleSyntax validates the Terraform syntax of the VLAN module
func TestVLANModuleSyntax(t *testing.T) {
	// ARRANGE
	modulePath := "../modules/vlan"

	// Skip if module directory doesn't exist
	if _, err := os.Stat(modulePath); os.IsNotExist(err) {
		t.Skipf("Module directory not found: %s", modulePath)
	}

	// ACT: Run terraform init -backend=false
	initCmd := exec.Command("terraform", "init", "-backend=false")
	initCmd.Dir = modulePath
	initOutput, err := initCmd.CombinedOutput()

	// ASSERT: Verify initialization succeeded
	if err != nil {
		t.Fatalf("Terraform init failed: %v\nOutput: %s", err, initOutput)
	}

	// ACT: Run terraform validate
	validateCmd := exec.Command("terraform", "validate")
	validateCmd.Dir = modulePath
	validateOutput, err := validateCmd.CombinedOutput()

	// ASSERT: Verify validation succeeded
	if err != nil {
		t.Fatalf("Terraform validate failed: %v\nOutput: %s", err, validateOutput)
	}

	// Confirm success message in validation output
	if !strings.Contains(string(validateOutput), "Success!") {
		t.Errorf("Terraform validate did not report success: %s", validateOutput)
	}
}

// TestVLANModulePlan checks if a terraform plan with the VLAN module generates
// the expected resources
func TestVLANModulePlan(t *testing.T) {
	// ARRANGE
	// Skip test if SKIP_PLAN is set
	if os.Getenv("SKIP_PLAN") == "true" {
		t.Skip("Skipping plan test due to SKIP_PLAN=true")
	}

	// Create temporary dir for testing
	tmpDir, err := os.MkdirTemp(".", "vlan-test-*")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create test configuration file
	modulePath := "../../modules/vlan"
	mainTF := fmt.Sprintf(`
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

module "vlan" {
  source = "%s"

  vlan_id     = 999
  bridge_name = "bridge0"
  vlan_cidr   = "10.99.9.0/24"
  gateway_ip  = "10.99.9.1"
  
  interface_lists   = ["vlans"]
  tagged_interfaces = ["ether2", "ether3"]
  dns_domain        = "test.example.com"
  wan_interface     = "ether1"
  security_zone     = "internal"
  disabled          = true
}

output "vlan_name" {
  value = module.vlan.vlan_name
}
`, modulePath)

	mainTFPath := filepath.Join(tmpDir, "main.tf")
	if err := os.WriteFile(mainTFPath, []byte(mainTF), 0644); err != nil {
		t.Fatalf("Failed to write main.tf: %v", err)
	}

	// Set environment variables for mock credentials if not testing with real router
	useRealRouter := os.Getenv("USE_REAL_ROUTER") == "true"
	if !useRealRouter {
		os.Setenv("MIKROTIK_HOST", "dummy.example.com")
		os.Setenv("MIKROTIK_USER", "dummy")
		os.Setenv("MIKROTIK_PASSWORD", "dummy")
	}

	// ACT: Run terraform init
	initCmd := exec.Command("terraform", "init")
	initCmd.Dir = tmpDir
	initOutput, err := initCmd.CombinedOutput()
	if err != nil {
		t.Fatalf("Terraform init failed: %v\nOutput: %s", err, initOutput)
	}

	// ACT: Run terraform plan
	planCmd := exec.Command("terraform", "plan", "-no-color")
	planCmd.Dir = tmpDir
	planOutput, err := planCmd.CombinedOutput()
	planOutputStr := string(planOutput)

	// ASSERT: Check plan output
	if useRealRouter && err != nil {
		t.Fatalf("Terraform plan failed with real router: %v\nOutput: %s", err, planOutputStr)
	}

	// If not using real router, we expect it to fail but still check for expected resources
	expectedPatterns := []string{
		"routeros_interface_vlan",
		"routeros_ip_address",
		"vlan_id\\s*=\\s*999",
		"name\\s*=\\s*\"vlan999\"",
	}

	for _, pattern := range expectedPatterns {
		re := regexp.MustCompile(pattern)
		if !re.MatchString(planOutputStr) {
			t.Errorf("Expected pattern '%s' not found in plan output", pattern)
		}
	}
}

// TestVLANModuleWithRealRouter tests the VLAN module against a real RouterOS device
func TestVLANModuleWithRealRouter(t *testing.T) {
	// ARRANGE
	// Skip if not testing with real router
	if os.Getenv("USE_REAL_ROUTER") != "true" {
		t.Skip("Skipping real router test (USE_REAL_ROUTER != true)")
	}

	// Verify router credentials are set
	host := os.Getenv("MIKROTIK_HOST")
	user := os.Getenv("MIKROTIK_USER")
	pass := os.Getenv("MIKROTIK_PASSWORD")

	if host == "" || user == "" || pass == "" {
		t.Fatal("MIKROTIK_HOST, MIKROTIK_USER and MIKROTIK_PASSWORD must be set for real router tests")
	}

	// Create temporary directory
	tmpDir, err := os.MkdirTemp(".", "vlan-real-test-*")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create test configuration
	mainTF := `
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

module "vlan" {
  source = "../../modules/vlan"

  vlan_id           = 999
  bridge_name       = "bridge0"
  vlan_cidr         = "10.99.9.0/24"
  gateway_ip        = "10.99.9.1"
  interface_lists   = ["vlans"]
  dns_domain        = "test.example.com"
  wan_interface     = "ether1"
  disabled          = true
}

output "vlan_name" {
  value = module.vlan.vlan_name
}
`
	mainTFPath := filepath.Join(tmpDir, "main.tf")
	if err := os.WriteFile(mainTFPath, []byte(mainTF), 0644); err != nil {
		t.Fatalf("Failed to write main.tf: %v", err)
	}

	// ACT: Initialize Terraform
	initCmd := exec.Command("terraform", "init")
	initCmd.Dir = tmpDir
	initOutput, err := initCmd.CombinedOutput()
	if err != nil {
		t.Fatalf("Terraform init failed: %v\nOutput: %s", err, initOutput)
	}

	// Skip apply/destroy unless explicitly enabled
	if os.Getenv("ENABLE_APPLY") != "true" {
		t.Log("Skipping apply/destroy (ENABLE_APPLY != true)")
		return
	}

	// ACT: Apply configuration
	applyCmd := exec.Command("terraform", "apply", "-auto-approve")
	applyCmd.Dir = tmpDir
	applyOutput, err := applyCmd.CombinedOutput()

	// ASSERT: Apply succeeded
	if err != nil {
		t.Fatalf("Terraform apply failed: %v\nOutput: %s", err, applyOutput)
	}

	// ACT: Get outputs
	outputCmd := exec.Command("terraform", "output", "-json")
	outputCmd.Dir = tmpDir
	outputJSON, err := outputCmd.CombinedOutput()

	// ASSERT: Check outputs
	if err != nil {
		t.Errorf("Failed to get outputs: %v", err)
	} else {
		// Check for vlan_name in output
		if !strings.Contains(string(outputJSON), "vlan999") {
			t.Errorf("Expected vlan_name=vlan999 in outputs, got: %s", outputJSON)
		}
	}

	// ACT: Destroy resources
	destroyCmd := exec.Command("terraform", "destroy", "-auto-approve")
	destroyCmd.Dir = tmpDir
	destroyOutput, err := destroyCmd.CombinedOutput()

	// ASSERT: Destroy succeeded
	if err != nil {
		t.Fatalf("Terraform destroy failed: %v\nOutput: %s", err, destroyOutput)
	}
}
