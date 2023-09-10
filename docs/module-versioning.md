# Module Versioning Policy

This document describes how tf-modules is versioned, when version numbers change, and how to perform a release.

## Version Scheme

tf-modules follows [Semantic Versioning](https://semver.org/) (`MAJOR.MINOR.PATCH`):

| Version component | When it changes |
|-------------------|----------------|
| **MAJOR** (`v2.0.0`) | Breaking changes: renamed required variables, removed outputs, changed default behaviour that was previously stable |
| **MINOR** (`v1.1.0`) | New features: new optional variables, new modules, new outputs, new resources behind a `false` default flag |
| **PATCH** (`v1.0.1`) | Non-breaking fixes: bug fixes, documentation corrections, formatting, security advisories |

## What Is a Breaking Change?

A change is **breaking** if a caller using the current public interface needs to modify their configuration to upgrade:

- Renaming a required variable (e.g., `cluster_version` → `kubernetes_version` with no default)
- Removing an output
- Changing the type of an existing variable
- Changing a default value that alters resource behaviour (e.g., switching a security control from `false` to `true` by default)
- Removing a resource that existed in state (triggers destroy/recreate)

A change is **not breaking** if:

- Adding a new optional variable with a sensible default
- Adding a new output
- Adding a new resource behind a `false` flag
- Internal refactors that preserve all Terraform resource addresses

When in doubt, treat a change as breaking and bump MAJOR.

## Backward Compatibility Promise

From `v1.0.0` onward:

- **MINOR releases**: callers can upgrade by running `terraform plan` — no variable changes required. Outputs may be added but never removed. Defaults are preserved.
- **PATCH releases**: safe to apply without a plan review. Documentation and bug fixes only.
- **MAJOR releases**: see [migration guide](migration-guide.md) for upgrade instructions.

## Deprecation Policy

Before removing a variable in a MAJOR release:

1. Mark it deprecated in the variable description: `Deprecated: use <new_name> instead.`
2. Add a `check` block or `validation` warning when both the old and new variables are set.
3. Keep the deprecated variable functional for at least one MINOR release cycle.
4. Document the removal in [CHANGELOG.md](../CHANGELOG.md) under the next MAJOR version.

Example:

```hcl
# Deprecated: use kubernetes_version. Kept for backward compatibility.
variable "cluster_version" {
  description = "Deprecated: use kubernetes_version. Kubernetes version for the EKS cluster."
  type        = string
  default     = null
}
```

## Release Workflow

### 1. Prepare the release

```bash
# Ensure the working tree is clean
git status

# Run the validate matrix locally
bash scripts/validate.sh

# Run a representative test subset
SKIP_EKS_TESTS=true SKIP_AKS_TESTS=true go test ./tests/... -v -timeout 20m

# Update CHANGELOG.md: move Unreleased → vX.Y.Z with today's date
vim CHANGELOG.md
git add CHANGELOG.md
git commit -m "docs: release vX.Y.Z"
```

### 2. Create the Git tag

```bash
git tag -a vX.Y.Z -m "Release vX.Y.Z"
git push origin vX.Y.Z
```

The tag triggers the GitHub Actions release workflow which:

- Runs the full terraform validate matrix
- Publishes a GitHub Release with the CHANGELOG section as release notes

### 3. Post-release

- Open a new `Unreleased` section at the top of CHANGELOG.md
- Communicate breaking changes to consumers via PR comment or Slack if applicable

## Consuming This Module

### Pin to a specific version (recommended for production)

```hcl
module "eks" {
  source = "github.com/YOUR_ORG/tf-modules//modules/aws/eks?ref=v1.0.0"
  # ...
}
```

### Pin to a minor release (acceptable for staging)

```hcl
module "eks" {
  source = "github.com/YOUR_ORG/tf-modules//modules/aws/eks?ref=v1.0"
  # Tracks patch releases within v1.0.x
}
```

### Track main (development only)

```hcl
module "eks" {
  source = "github.com/YOUR_ORG/tf-modules//modules/aws/eks"
  # WARNING: main may contain unreleased breaking changes
}
```

Always run `terraform init -upgrade` after changing a module version reference.

## Module Compatibility Matrix

| tf-modules version | Terraform | AWS provider | AzureRM provider | Helm provider |
|--------------------|-----------|--------------|------------------|---------------|
| `v1.0.0` | `>= 1.4.0` | `~> 5.0` | `~> 3.0` | `~> 2.0` |

Check `modules/<cloud>/<module>/versions.tf` for per-module constraints.
