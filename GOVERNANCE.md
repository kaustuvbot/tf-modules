# Platform Governance

This document defines operational ownership, escalation paths, and
change management processes for this Terraform platform.

## Module Ownership

| Module Group | Owner | On-Call Rotation |
|---|---|---|
| AWS networking (vpc, s3-state, dynamodb-lock) | Platform Team | Yes |
| AWS compute (eks, eks-addons) | Platform Team | Yes |
| AWS security (iam, kms, guardduty, security-hub) | Security Team | Yes |
| AWS observability (logging, monitoring, budgets) | Observability Team | No |
| Azure networking (vnet, resource-group) | Platform Team | Yes |
| Azure compute (aks) | Platform Team | Yes |
| Core / multi modules | Platform Team | Yes |

## Change Management

### Breaking Changes

A change is considered **breaking** if it:
- Removes or renames a module output
- Removes or renames a required input variable
- Changes the default value of a variable in a way that alters behavior
- Forces resource replacement on existing deployments

Breaking changes require:
1. A `BREAKING CHANGE` label in the PR
2. A migration guide section added to `docs/migration-guide.md`
3. A minimum 1-week notice period for consumers
4. A major version bump in the module changelog

### Standard Changes

Standard changes (new optional variables, new outputs, bug fixes) follow:
1. PR with description referencing the relevant module
2. Terratest suite must pass
3. One approval required

## Escalation Paths

| Scenario | First Responder | Escalate To |
|---|---|---|
| Production apply failure | Module owner | Platform Team lead |
| State corruption | Module owner | Platform Team lead + infra manager |
| Security finding (GuardDuty/Defender) | Security Team | CISO (if P1) |
| Cost spike (budget alert) | Module owner | FinOps lead |

## Runbook Links

- [AWS EKS Runbook](docs/aws-runbook.md)
- [Karpenter Migration Guide](docs/karpenter-migration.md)
- [Testing Guide](docs/testing.md)
- [Troubleshooting](docs/troubleshooting.md)

## Release Process

1. Cut release branch: `release/vX.Y.Z`
2. Update `CHANGELOG.md`
3. Open PR against `main`
4. Require 2 approvals + CI green
5. Merge and tag: `git tag vX.Y.Z`
6. GitHub Release created automatically by release workflow
