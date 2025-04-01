#!/bin/bash
# Enhanced test runner for RouterOS VLAN module

# Set error handling
set -e

# Get the directory of this script
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Running Enhanced RouterOS VLAN Module Tests${NC}"
echo "=================================================="

# Setup phase - check for required tools
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed${NC}"
    exit 1
fi

# Check for Go
if ! command -v go &> /dev/null; then
    echo -e "${RED}Error: Go is not installed${NC}"
    exit 1
fi

# Run the basic tests
echo -e "${YELLOW}Running basic structure and syntax tests...${NC}"
go test -v -run TestVLANModuleStructure
go test -v -run TestVLANModuleSyntax

# Check if we should run tests with a real router
if [ "${USE_REAL_ROUTER}" = "true" ]; then
    echo -e "${YELLOW}Running tests with real RouterOS device...${NC}"
    
    # Verify credentials are set
    if [ -z "${MIKROTIK_HOST}" ] || [ -z "${MIKROTIK_USER}" ] || [ -z "${MIKROTIK_PASSWORD}" ]; then
        echo -e "${RED}Error: To test with a real RouterOS device, you must set:${NC}"
        echo "MIKROTIK_HOST, MIKROTIK_USER, and MIKROTIK_PASSWORD environment variables"
        exit 1
    fi
    
    # Prepare testing directory
    echo -e "${YELLOW}Preparing test environment...${NC}"
    TEST_DIR="vlan_module_test_env"
    mkdir -p $TEST_DIR
    cp vlan_module_test/*.tf $TEST_DIR/
    
    # Initialize test directory
    cd $TEST_DIR
    terraform init
    
    # Run plan
    echo -e "${YELLOW}Running terraform plan...${NC}"
    terraform plan -out=tfplan
    
    # Run apply if enabled
    if [ "${ENABLE_APPLY}" = "true" ]; then
        echo -e "${YELLOW}Applying test configuration (disabled=true)...${NC}"
        terraform apply -auto-approve
        
        # Get outputs
        echo -e "${YELLOW}Verifying outputs...${NC}"
        terraform output
        
        # Cleanup
        echo -e "${YELLOW}Cleaning up test resources...${NC}"
        terraform destroy -auto-approve
    fi
    
    cd ..
    rm -rf $TEST_DIR
else
    echo -e "${YELLOW}Skipping real RouterOS device tests.${NC}"
    echo "To run these tests, set USE_REAL_ROUTER=true and required credentials."
fi

echo -e "${GREEN}Tests completed successfully!${NC}"