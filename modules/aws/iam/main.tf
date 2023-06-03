# -----------------------------------------------------------------------------
# AWS IAM Module
# -----------------------------------------------------------------------------
# Manages GitHub OIDC federation and CI/CD roles for Terraform automation.
#
# Resources created:
#   - GitHub OIDC identity provider
#   - CI plan role (read-only)
#   - CI apply role (read-write)
#
# This module will be built incrementally across commits 21–24.
# -----------------------------------------------------------------------------
