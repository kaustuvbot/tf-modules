# Module Tests

Integration tests for tf-modules using [Terratest](https://terratest.gruntwork.io/).

## Prerequisites

- Go 1.21+
- Terraform 1.4+
- **AWS tests**: AWS credentials with sufficient permissions (or the CI plan/apply roles)
- **Azure tests**: Azure CLI authenticated (`az login`) or service principal via environment variables

## Running Tests

```bash
# Install dependencies
cd tests && go mod download

# Run all AWS tests (requires live AWS account)
go test ./aws/... -v -timeout 30m

# Run all Azure tests (requires live Azure subscription)
go test ./azure/... -v -timeout 45m

# Run a specific test
go test ./aws/ -run TestVpcHappyPath -v -timeout 15m
go test ./azure/ -run TestVnetHappyPath -v -timeout 15m

# Run with parallel limit
go test ./aws/... -v -timeout 60m -parallel 2
go test ./azure/... -v -timeout 60m -parallel 2
```

## Test Structure

```
tests/
├── go.mod
├── README.md
├── aws/
│   ├── helpers_test.go     # Shared utilities
│   ├── vpc_test.go         # VPC module tests
│   └── eks_test.go         # EKS module smoke tests
└── azure/
    ├── helpers_test.go     # Shared utilities
    ├── vnet_test.go        # VNet module tests
    └── aks_test.go         # AKS module smoke tests
```

## Cost Warning

Integration tests create **real cloud resources** and incur costs. Tests clean up after themselves via `defer terraform.Destroy()`, but always verify no resources remain if a test is interrupted.

Estimated cost per test run:

### AWS
| Test | Estimated cost |
|------|---------------|
| VPC tests | < $0.01 (no NAT gateway by default) |
| EKS tests | ~$0.20–0.50 (cluster runs for ~10 minutes) |

### Azure
| Test | Estimated cost |
|------|---------------|
| VNet tests | < $0.01 |
| AKS tests | ~$0.30–0.80 (cluster runs for ~15 minutes) |

## Environment Variables

| Variable | Cloud | Description |
|----------|-------|-------------|
| `AWS_REGION` | AWS | Override test region (default: `us-east-1`) |
| `AZURE_LOCATION` | Azure | Override test region (default: `eastus`) |
| `TF_LOG` | Both | Set to `DEBUG` for Terraform debug output |
| `SKIP_EKS_TESTS` | AWS | Set to `true` to skip expensive EKS tests |
| `SKIP_AKS_TESTS` | Azure | Set to `true` to skip expensive AKS tests |
