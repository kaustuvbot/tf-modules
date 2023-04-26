# AWS Backend Setup Guide

This guide covers bootstrapping and configuring S3 + DynamoDB as a Terraform remote backend.

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.4.0
- An AWS account with permissions to create S3 buckets and DynamoDB tables

## Architecture

```
┌─────────────────┐     ┌──────────────────┐
│   S3 Bucket     │     │  DynamoDB Table   │
│  (State Store)  │     │  (State Lock)     │
│                 │     │                   │
│  - Versioned    │     │  - PAY_PER_REQUEST│
│  - Encrypted    │     │  - LockID key     │
│  - No public    │     │  - Optional TTL   │
│    access       │     │                   │
└─────────────────┘     └──────────────────┘
```

## Step 1: Bootstrap the Backend

The `bootstrap/` directory creates the state infrastructure itself. Since this is a chicken-and-egg problem (you need state storage to store state), the bootstrap uses local state.

```bash
cd bootstrap/

# Initialize with local state
terraform init

# Review what will be created
terraform plan -var="project=tfmodules" -var="region=us-east-1"

# Apply
terraform apply -var="project=tfmodules" -var="region=us-east-1"
```

This creates:
- S3 bucket: `tfmodules-terraform-state-us-east-1`
- DynamoDB table: `tfmodules-terraform-lock`

## Step 2: Configure Backend in Environments

Copy the backend template and fill in your values:

```hcl
# environments/dev/backend.tf
terraform {
  backend "s3" {
    bucket         = "tfmodules-terraform-state-us-east-1"
    key            = "dev/platform/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tfmodules-terraform-lock"
    encrypt        = true
  }
}
```

### State Key Convention

Use the pattern: `<environment>/<component>/terraform.tfstate`

| Environment | Component | State Key |
|-------------|-----------|-----------|
| dev | platform | `dev/platform/terraform.tfstate` |
| staging | platform | `staging/platform/terraform.tfstate` |
| prod | platform | `prod/platform/terraform.tfstate` |

## Step 3: Migrate Local State to S3

If you have existing local state, migrate it:

```bash
cd environments/dev/

# Add the backend configuration (Step 2)
# Then re-initialize — Terraform will detect the change
terraform init

# Terraform will ask:
# "Do you want to copy existing state to the new backend?"
# Answer: yes
```

## Using the Reusable Modules

Instead of the monolithic `bootstrap/`, you can compose the backend from individual modules:

```hcl
module "state_bucket" {
  source = "../../modules/aws/s3-state"

  bucket_name = "myproject-terraform-state-us-east-1"

  tags = {
    Purpose = "terraform-state"
  }
}

module "lock_table" {
  source = "../../modules/aws/dynamodb-lock"

  table_name = "myproject-terraform-lock"
  enable_ttl = true

  tags = {
    Purpose = "terraform-lock"
  }
}
```

## Troubleshooting

### Access Denied on S3

- Verify your IAM user/role has `s3:GetObject`, `s3:PutObject`, `s3:ListBucket` on the state bucket
- Check the bucket policy isn't blocking your principal
- Ensure the KMS key policy allows your principal (if using KMS encryption)

### State Lock Stuck

If a lock is stuck (e.g., process crashed mid-apply):

```bash
# Check who holds the lock
aws dynamodb get-item \
  --table-name tfmodules-terraform-lock \
  --key '{"LockID":{"S":"tfmodules-terraform-state-us-east-1/dev/platform/terraform.tfstate"}}'

# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### State File Not Found

- Verify the `key` in your backend config matches the path used during initial setup
- Check the S3 bucket region matches your backend config
- List objects: `aws s3 ls s3://tfmodules-terraform-state-us-east-1/ --recursive`
