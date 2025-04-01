# RouterOS VLAN Module Test

This is a minimal test for validating the RouterOS VLAN Terraform module without requiring actual RouterOS hardware.

## Features

- Terraform syntax validation
- Module structure verification
- Variables validation
- Plan verification

## Prerequisites

- Go 1.16+
- Terraform 0.14+

## Getting Started

1. Place this directory next to your RouterOS Terraform modules (assuming the VLAN module is at `../modules/vlan/`)
2. Run the test:

```bash
./run_test.sh