# Example: Production-Hardened AWS EKS

This example deploys a production-grade EKS cluster with hardened defaults.

## What's Included

- VPC with private subnets across 3 AZs
- NAT gateway per AZ (no single point of failure)
- VPC endpoints: SSM, ECR, S3 (no internet for cluster traffic)
- EKS private API endpoint only
- Secrets encryption (KMS)
- System node group (ON_DEMAND) + workload node group (SPOT)
- Karpenter for node autoscaling
- ALB Controller, ExternalDNS, cert-manager, Node Termination Handler

## Usage

```bash
terraform init
terraform plan -var="project=myapp" -var="region=us-east-1"
terraform apply
```

## Security Notes

- No public API endpoint — kubectl access via VPN or bastion only
- Node IMDSv2 is enforced via launch template in the EKS module
- SPOT interruptions handled gracefully by AWS Node Termination Handler
