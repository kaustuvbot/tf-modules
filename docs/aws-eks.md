# AWS EKS Deep Guide

## Architecture

The EKS module creates:

```
EKS Cluster
├── Cluster IAM Role (EKSClusterPolicy + VPCResourceController)
├── Control Plane (managed by AWS)
│   ├── API Server
│   ├── etcd
│   └── Control plane logging → CloudWatch
├── OIDC Provider (for IRSA)
└── Managed Node Groups
    ├── Node Group IAM Role (WorkerNode + CNI + ECR policies)
    ├── System nodes (ON_DEMAND)
    └── Workload nodes (SPOT or ON_DEMAND)
```

## Node Group Strategy

### System nodes

Use `ON_DEMAND` instances for system components (CoreDNS, kube-proxy, etc.). These must be always available.

```hcl
system = {
  instance_types = ["t3.medium"]
  desired_size   = 2
  min_size       = 2
  max_size       = 4
  labels = {
    role = "system"
  }
}
```

### Workload nodes

Use `SPOT` instances for cost savings on stateless workloads that can tolerate interruptions.

```hcl
workload = {
  instance_types = ["t3.large", "t3a.large", "m5.large"]
  desired_size   = 3
  min_size       = 1
  max_size       = 20
  capacity_type  = "SPOT"
  labels = {
    role = "workload"
  }
}
```

## Control Plane Logging

All five log types are enabled by default:

| Log Type | What It Captures | Cost Impact |
|----------|-----------------|-------------|
| `api` | API server requests | Medium |
| `audit` | API audit events | High |
| `authenticator` | Auth decisions | Low |
| `controllerManager` | Controller operations | Low |
| `scheduler` | Scheduling decisions | Low |

For dev/staging, consider disabling `audit` to reduce costs:

```hcl
enabled_cluster_log_types = ["api", "authenticator", "controllerManager", "scheduler"]
```

## Secrets Encryption

When `kms_key_arn` is set, Kubernetes secrets are encrypted at rest using envelope encryption. The EKS control plane encrypts secrets with a data encryption key (DEK), which is itself encrypted with your KMS key.

This is **strongly recommended for production** as it protects sensitive data (passwords, tokens, certificates) stored in etcd.

## Connecting to the Cluster

After deployment, configure kubectl:

```bash
aws eks update-kubeconfig \
  --name myproject-prod-eks \
  --region us-east-1
```

## Known Limitations

1. **Public endpoint enabled**: The API server is accessible from the internet by default. Commit 81 will add endpoint access controls.
2. **No cluster autoscaler**: Autoscaling configuration will be added in Batch 15 (commits 141–142).
3. **No add-ons**: ALB controller, ExternalDNS, and cert-manager will be added in Batch 5.
4. **No pod security**: Pod security baselines will be added in Phase 3.
