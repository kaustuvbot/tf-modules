# Azure Terraform State Backend

## Overview

For Azure environments, Terraform state is stored in Azure Blob Storage with state locking via lease mechanism.

## Setup

### 1. Create the state storage account

```bash
# Create resource group
az group create --name rg-tfstate --location eastus

# Create storage account (name must be globally unique)
az storage account create \
  --name sttfstate$RANDOM \
  --resource-group rg-tfstate \
  --location eastus \
  --sku Standard_LRS \
  --encryption-services blob \
  --min-tls-version TLS1_2

# Create blob container
az storage container create \
  --name tfstate \
  --account-name <storage-account-name>
```

### 2. Configure backend in environments

```hcl
# environments/dev/backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstateXXXX"
    container_name       = "tfstate"
    key                  = "dev/terraform.tfstate"
  }
}
```

## Authentication

GitHub Actions uses OIDC federation with Azure:

```yaml
- uses: azure/login@v1
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

Required GitHub secrets: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`

## State Locking

Azure Blob Storage uses lease-based locking. If a lock is stuck:

```bash
az storage blob lease break \
  --blob-name dev/terraform.tfstate \
  --container-name tfstate \
  --account-name <storage-account-name>
```

## Comparison with AWS Backend

| Feature | AWS (S3 + DynamoDB) | Azure (Blob Storage) |
|---------|--------------------|--------------------|
| State storage | S3 | Azure Blob |
| Locking | DynamoDB | Blob lease |
| Encryption | SSE-S3 or KMS | Azure Storage SSE |
| Versioning | S3 versioning | Blob versioning |
| Bootstrap | Separate module | `az` CLI commands |
