#!/usr/bin/env bash
set -euo pipefail

# Format all Terraform files recursively
echo "Running terraform fmt..."
terraform fmt -recursive -diff .
echo "Done."
