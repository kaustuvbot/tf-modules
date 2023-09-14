# Platform Blueprint

The `modules/multi/platform-blueprint` module is a multi-cloud orchestration
entry point that composes cloud-specific stacks (networking + compute + observability)
behind a uniform interface.

## Design Goals

- Single module call deploys a full platform stack on any supported cloud
- Outputs use cloud-agnostic keys (`cluster_endpoint`, `network_id`)
- Cloud-specific configuration passed via typed `aws_config` / `azure_config` objects
- Easy to extend: adding GCP requires only a `gcp.tf` + `gcp-stack/` sub-module

## Architecture

```
platform-blueprint/
├── main.tf          # locals, common_tags, cloud routing
├── variables.tf     # cloud, project, environment, aws_config, azure_config
├── outputs.tf       # cluster_endpoint, network_id, common_tags
├── aws.tf           # conditional module.aws_stack
├── azure.tf         # conditional module.azure_stack
├── aws-stack/       # vpc + eks + logging composition
└── azure-stack/     # rg + vnet + aks + monitoring composition
```

## Usage

### AWS Platform

```hcl
module "platform" {
  source      = "../../modules/multi/platform-blueprint"
  cloud       = "aws"
  project     = "myapp"
  environment = "prod"

  aws_config = {
    region             = "us-east-1"
    vpc_cidr           = "10.0.0.0/16"
    availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
    eks_version        = "1.29"
    enable_nat_gateway = true
  }

  tags = { CostCenter = "platform" }
}
```

### Azure Platform

```hcl
module "platform" {
  source      = "../../modules/multi/platform-blueprint"
  cloud       = "azure"
  project     = "myapp"
  environment = "prod"

  azure_config = {
    location               = "eastus"
    vnet_cidr              = "10.0.0.0/16"
    subscription_id        = var.subscription_id
    kubernetes_version     = "1.29"
    enable_private_cluster = true
  }

  tags = { CostCenter = "platform" }
}
```

## Outputs

| Output | Type | Description |
|---|---|---|
| `cloud` | string | Target cloud (`aws` or `azure`) |
| `project` | string | Project name |
| `environment` | string | Environment name |
| `cluster_endpoint` | string | Kubernetes API server endpoint |
| `network_id` | string | VPC ID (AWS) or VNet resource ID (Azure) |
| `common_tags` | map(string) | Merged tags applied to all resources |

## Extending for GCP

1. Add `gcp_config` variable to `variables.tf`
2. Create `gcp.tf` with `module "gcp_stack"` block
3. Create `gcp-stack/` with VPC + GKE composition
4. Update `outputs.tf` to handle `cloud == "gcp"`
