#!/bin/bash
# Simple test runner for RouterOS module interface tests

# Set error handling
set -e

# Get the directory of this script
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
echo "$SCRIPT_DIR"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage
function show_usage() {
    echo -e "${BLUE}RouterOS Module Interface Testing${NC}"
    echo "Usage: $0 [module]"
    echo ""
    echo "Arguments:"
    echo "  module    Specify module to test (all, vlan, firewall, dns, ntp, backup, monitoring)"
    echo ""
    echo "Examples:"
    echo "  $0                  # Test all modules"
    echo "  $0 vlan             # Test only the VLAN module"
    echo "  $0 firewall         # Test only the Firewall module"
}

# Parse command line arguments
MODULE="all"

if [ $# -eq 1 ]; then
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        show_usage
        exit 0
    fi
    MODULE="$1"
fi

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo -e "${RED}Error: Go is not installed${NC}"
    exit 1
fi

# Set environment variable for the test
export TEST_MODULE="$MODULE"

echo -e "${BLUE}Running Module Interface Tests${NC}"
echo "=================================================="
echo -e "Module: ${YELLOW}$MODULE${NC}"
echo "=================================================="

# Run the tests
go test -v -run TestAllModuleInterfaces

RESULT=$?
if [ $RESULT -eq 0 ]; then
    echo -e "${GREEN}All tests passed successfully!${NC}"
else
    echo -e "${RED}Tests failed!${NC}"
fi

exit $RESULT