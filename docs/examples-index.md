# Examples Index

This page catalogs all examples in the `examples/` directory.

## Available Examples

| Example | Cloud | Complexity | Purpose |
|---|---|---|---|
| [aws-vpc-simple](../examples/aws-vpc-simple/) | AWS | Low | Minimal VPC with public/private subnets |
| [aws-complete](../examples/aws-complete/) | AWS | High | Full AWS platform: VPC + EKS + logging + IAM |
| [aws-eks-with-addons](../examples/aws-eks-with-addons/) | AWS | Medium | EKS cluster with ALB controller, ExternalDNS, cert-manager |
| [aws-eks-production](../examples/aws-eks-production/) | AWS | High | Hardened EKS: private API, IMDSv2, Karpenter, SPOT |
| [azure-complete](../examples/azure-complete/) | Azure | High | Full Azure platform: RG + VNet + AKS + monitoring |
| [azure-aks-private](../examples/azure-aks-private/) | Azure | Medium | Private AKS cluster with private-dns zone wiring |

## Choosing an Example

- **Learning the module** → start with `aws-vpc-simple` or `azure-complete`
- **Production deployment** → use `aws-eks-production` or `azure-aks-private`
- **Full platform** → use `aws-complete` or `azure-complete`

## Running an Example

```bash
cd examples/<example-name>
terraform init
terraform plan
terraform apply
```

All examples use local state by default. For real deployments, configure
a remote backend (see [docs/aws-backend.md](../docs/aws-backend.md) or
[docs/azure-backend.md](../docs/azure-backend.md)).

## Adding a New Example

1. Create a directory under `examples/`
2. Add `main.tf`, `variables.tf`, `outputs.tf`, `README.md`
3. Reference modules using relative paths: `source = "../../modules/aws/vpc"`
4. Add an entry to this index
5. Ensure `terraform validate` passes in CI
