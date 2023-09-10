# Testing Guide

## Overview

This project uses [Terratest](https://terratest.gruntwork.io/) for integration tests. Tests deploy real infrastructure against live AWS/Azure accounts and validate actual resource attributes. All tests clean up after themselves via `defer terraform.Destroy()`.

## Test Matrix

### AWS Tests (`tests/aws/`)

| Test file | Module | Function | Est. time | Est. cost | Skip guard |
|-----------|--------|----------|-----------|-----------|-----------|
| `vpc_test.go` | `aws/vpc` | `TestVpcHappyPath` | ~2 min | <$0.01 | — |
| `iam_test.go` | `aws/iam` | `TestIamOidcOutputs` | ~1 min | <$0.01 | `SKIP_IAM_TESTS` |
| `s3_state_test.go` | `aws/s3-state` | `TestS3StateBucketOutputs` | ~1 min | <$0.01 | `SKIP_S3_TESTS` |
| `dynamodb_lock_test.go` | `aws/dynamodb-lock` | `TestDynamoDBLockOutputs` | ~1 min | <$0.01 | `SKIP_DYNAMODB_TESTS` |
| `kms_test.go` | `aws/kms` | `TestKmsKeyOutputs` | ~1 min | <$0.01 | `SKIP_KMS_TESTS` |
| `logging_test.go` | `aws/logging` | `TestLoggingCloudTrailOutputs` | ~3 min | ~$0.05 | `SKIP_LOGGING_TESTS` |
| `monitoring_test.go` | `aws/monitoring` | `TestMonitoringAlarmOutputs` | ~1 min | <$0.01 | `SKIP_MONITORING_TESTS` |
| `budgets_test.go` | `aws/budgets` | `TestBudgetNameOutput` | ~1 min | <$0.01 | `SKIP_BUDGET_TESTS` |
| `ecr_test.go` | `aws/ecr` | `TestEcrRepositoryOutputs` | ~1 min | <$0.01 | `SKIP_ECR_TESTS` |
| `eks_test.go` | `aws/eks` | `TestEksSmokeTest` | ~12 min | ~$0.30 | `SKIP_EKS_TESTS` |

### Azure Tests (`tests/azure/`)

| Test file | Module | Function | Est. time | Est. cost | Skip guard |
|-----------|--------|----------|-----------|-----------|-----------|
| `resource_group_test.go` | `azure/resource-group` | `TestResourceGroupOutputs` | ~1 min | <$0.01 | `SKIP_RG_TESTS` |
| `vnet_test.go` | `azure/vnet` | `TestVnetOutputs` | ~2 min | <$0.01 | `SKIP_VNET_TESTS` |
| `keyvault_test.go` | `azure/key-vault` | `TestKeyVaultOutputs` | ~2 min | <$0.01 | `SKIP_KEYVAULT_TESTS` |
| `container_registry_test.go` | `azure/container-registry` | `TestContainerRegistryOutputs` | ~2 min | <$0.01 | `SKIP_ACR_TESTS` |
| `private_dns_test.go` | `azure/private-dns` | `TestPrivateDnsOutputs` | ~2 min | <$0.01 | `SKIP_PRIVATE_DNS_TESTS` |
| `aks_test.go` | `azure/aks` | `TestAksSmokeTest` | ~10 min | ~$0.50 | `SKIP_AKS_TESTS` |

## Prerequisites

```bash
# Install Go 1.21+
go version

# Install Terraform 1.4+
terraform version

# Configure AWS credentials
aws sts get-caller-identity

# Configure Azure credentials (for Azure tests)
az account show
```

## Running Tests Locally

### AWS tests

```bash
cd tests

# Install Go dependencies
go mod download

# Run all AWS tests (uses default region us-east-1)
go test ./aws/... -v -timeout 30m

# Skip expensive tests for fast feedback
SKIP_EKS_TESTS=true go test ./aws/... -v -timeout 10m

# Skip all but VPC and IAM (very fast smoke check)
SKIP_EKS_TESTS=true SKIP_LOGGING_TESTS=true SKIP_MONITORING_TESTS=true \
  go test ./aws/... -v -timeout 10m

# Run a specific test
go test ./aws/ -run TestVpcHappyPath -v -timeout 10m

# Use a different region
AWS_REGION=eu-west-1 go test ./aws/... -v -timeout 30m
```

### Azure tests

```bash
# Run all Azure tests
go test ./azure/... -v -timeout 30m

# Skip AKS tests (expensive)
SKIP_AKS_TESTS=true go test ./azure/... -v -timeout 10m

# Run with a specific Azure location
AZURE_LOCATION=westeurope go test ./azure/... -v -timeout 30m
```

## Running Tests in CI

Tests run in the GitHub Actions pipeline with the CI plan role. Slow/expensive tests are skipped by default:

```yaml
- name: Run AWS tests
  env:
    SKIP_EKS_TESTS: "true"
    SKIP_LOGGING_TESTS: "true"
  run: go test ./tests/aws/... -v -timeout 20m

- name: Run Azure tests
  env:
    SKIP_AKS_TESTS: "true"
  run: go test ./tests/azure/... -v -timeout 20m
```

To enable full test coverage (e.g., for release validation), remove the skip environment variables and ensure the CI role has the required IAM/RBAC permissions.

## What Tests Validate

### AWS

**`vpc_test.go`** — VPC CIDR, subnet count and VPC membership, IGW presence, required tags

**`iam_test.go`** — OIDC provider ARN and thumbprint format

**`s3_state_test.go`** — Bucket name, ARN prefix, versioning status

**`dynamodb_lock_test.go`** — Table name match, ARN prefix `arn:aws:dynamodb:`

**`kms_test.go`** — Key ARN and key ID are non-empty for enabled keys

**`logging_test.go`** — CloudTrail ARN is non-empty

**`monitoring_test.go`** — Alarm ARNs contain `alarm/` prefix

**`budgets_test.go`** — Budget name and ARN are non-empty

**`ecr_test.go`** — Repository URL format (`dkr.ecr`), ARN structure

**`eks_test.go`** — Cluster name, endpoint, CA data, OIDC ARN, node role ARN, autoscaler role ARN

### Azure

**`resource_group_test.go`** — Name contains project, ID starts with `/subscriptions/`

**`vnet_test.go`** — VNet ID and address space are non-empty

**`keyvault_test.go`** — `vault_uri` and `key_vault_id` are non-empty

**`container_registry_test.go`** — `login_server` ends with `.azurecr.io`

**`private_dns_test.go`** — Zone ID and VNet link IDs are non-empty

**`aks_test.go`** — Cluster name, cluster ID, OIDC issuer URL, node pool IDs

## Test Isolation

Each test run uses a unique 4-digit ID suffix (e.g., `test-1234-vpc`) to prevent conflicts between parallel runs. Resources are always destroyed via `defer terraform.Destroy()`.

If a test is interrupted, clean up orphaned resources by searching the AWS Console or Azure Portal for resources tagged `ManagedBy=terratest`.

## Adding New Tests

1. Create `tests/aws/<module>_test.go` or `tests/azure/<module>_test.go`
2. Follow the pattern: `InitAndApplyE` → validate outputs → `defer Destroy`
3. Use `uniqueID(t)` for resource name suffix
4. Add a `SKIP_<MODULE>_TESTS` guard for slow or expensive tests
5. Add the test to the matrix tables in this doc
