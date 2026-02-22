# AWS Module Upgrade Guide

Guide for upgrading EKS clusters and AWS modules in this repository.

## EKS Cluster Upgrades

### Upgrading EKS Kubernetes Version

EKS Kubernetes version upgrades require careful planning:

1. **Check Supported Versions**
   ```bash
   aws eks describe-addon-versions --kubernetes-version 1.30
   ```

2. **Update Module Version**
   In your terraform configuration:
   ```hcl
   module "eks" {
     source = "../../modules/aws/eks"
     # ...
     kubernetes_version = "1.30"  # upgrade from 1.29
   }
   ```

3. **Plan and Apply**
   ```bash
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

4. **Verify Nodes**
   ```bash
   kubectl get nodes
   kubectl version
   ```

### Node Group Upgrades

EKS managed node groups upgrade automatically when the control plane upgrades.
For self-managed nodes, use node refresh strategy or replace nodes manually.

### Addon Compatibility

Check addon compatibility before upgrading:

| Kubernetes | coredns | vpc-cni | kube-proxy |
|------------|---------|---------|------------|
| 1.30       | v1.11.1 | v1.18.1 | v1.30.1   |
| 1.29       | v1.10.1 | v1.17.0 | v1.29.4   |
| 1.28       | v1.9.3  | v1.16.0 | v1.28.7   |

## Module Version Upgrades

### Terraform Provider Updates

Update provider constraints in `versions.tf`:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
  }
}
```

Run:
```bash
terraform init -upgrade
terraform plan
```

### Migrating Between Module Versions

When module structure changes:

1. Review the module's CHANGELOG or release notes
2. Run `terraform plan` to identify changes
3. Update variable values if renamed
4. Apply changes with `terraform apply`

## Common Upgrade Scenarios

### VPC Module

When upgrading VPC CIDR or subnet configuration:

1. Check for existing resources that may conflict
2. Plan carefully — CIDR changes require new VPC
3. Update route tables and security groups as needed

### KMS Key Rotation

Enable key rotation for existing keys:

```hcl
module "kms" {
  # ...
  enable_key_rotation = true
}
```

Rotation applies to new key versions; existing versions remain valid for decryption.

### ECR Lifecycle Policy

Update retention counts:

```hcl
module "ecr" {
  repositories = {
    myapp = {
      untagged_expiry_days = 7   # was 14
      tagged_keep_count    = 50   # was 30
    }
  }
}
```

## Rollback Procedures

If an upgrade causes issues:

1. **Terraform State**
   ```bash
   terraform state list
   terraform state show <resource>
   ```

2. **Restore Previous Version**
   ```bash
   git checkout <previous-commit>
   terraform apply
   ```

3. **EKS Rollback**
   Not supported — EKS only supports upgrades, not downgrades.
   Create new cluster if critical issue occurs.

## Testing Upgrades

1. Test in non-production environment first
2. Run `terraform plan` to review changes
3. Check CloudWatch logs after apply
4. Verify application functionality
