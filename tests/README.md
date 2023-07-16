# Module Tests

Integration tests for tf-modules using [Terratest](https://terratest.gruntwork.io/).

## Prerequisites

- Go 1.21+
- Terraform 1.4+
- AWS credentials with sufficient permissions (or the CI plan/apply roles)

## Running Tests

```bash
# Install dependencies
cd tests && go mod download

# Run all AWS tests (requires live AWS account)
go test ./aws/... -v -timeout 30m

# Run a specific test
go test ./aws/ -run TestVpcHappyPath -v -timeout 15m

# Run with parallel limit
go test ./aws/... -v -timeout 60m -parallel 2
```

## Test Structure

```
tests/
├── go.mod
├── README.md
└── aws/
    ├── helpers_test.go     # Shared utilities
    ├── vpc_test.go         # VPC module tests
    └── eks_test.go         # EKS module smoke tests
```

## Cost Warning

Integration tests create **real AWS resources** and incur costs. Tests clean up after themselves via `defer terraform.Destroy()`, but always verify no resources remain if a test is interrupted.

Estimated cost per test run:
- VPC tests: < $0.01 (no NAT gateway by default)
- EKS tests: ~$0.20–0.50 (cluster runs for ~10 minutes)

## Environment Variables

| Variable | Description |
|----------|-------------|
| `AWS_REGION` | Override test region (default: us-east-1) |
| `TF_LOG` | Set to `DEBUG` for Terraform debug output |
| `SKIP_EKS_TESTS` | Set to `true` to skip expensive EKS tests |
