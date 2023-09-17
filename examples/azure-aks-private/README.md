# Example: Private AKS Cluster with Private DNS

Deploys a private AKS cluster with a private DNS zone for endpoint resolution
and Azure Key Vault integration for secrets.

## What's Included

- Azure Resource Group
- VNet with AKS-dedicated subnet
- Private DNS zone linked to VNet (for private AKS API resolution)
- AKS with private cluster enabled
- No public API endpoint

## Usage

```bash
terraform init
terraform plan -var="subscription_id=<your-sub-id>"
terraform apply
```
