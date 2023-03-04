#!/usr/bin/env bash
set -euo pipefail

# Validate all Terraform modules
MODULES_DIR="modules"
EXIT_CODE=0

if [ ! -d "$MODULES_DIR" ]; then
  echo "No modules directory found, skipping."
  exit 0
fi

for dir in $(find "$MODULES_DIR" -name "*.tf" -exec dirname {} \; | sort -u); do
  echo "Validating: $dir"
  pushd "$dir" > /dev/null
  terraform init -backend=false > /dev/null 2>&1
  if ! terraform validate; then
    EXIT_CODE=1
  fi
  popd > /dev/null
done

exit $EXIT_CODE
