# Karpenter Migration Guide

Migrating from Cluster Autoscaler (managed via `enable_cluster_autoscaler_irsa`
on the EKS module) to Karpenter (managed via `enable_karpenter` on the
eks-addons module).

---

## Overview

| | Cluster Autoscaler | Karpenter |
|--|-------------------|-----------|
| **Provisioning** | Scales existing node groups (ASGs) | Directly provisions EC2 instances |
| **Speed** | 2–5 minutes per scale-out | 30–60 seconds per scale-out |
| **Bin packing** | Node group granularity | Per-pod, bin-packs onto smallest viable node |
| **SPOT** | Requires pre-configured instance pools | Selects best SPOT pool at provision time |
| **Config** | `node_groups` in EKS module | `NodePool` + `EC2NodeClass` CRDs |

---

## Prerequisites

- Terraform `>= 1.5`
- EKS cluster running Kubernetes `>= 1.27`
- AWS provider `~> 5.0`
- `eks-addons` module with `enable_karpenter = true`

---

## Migration Steps

### Step 1 — Enable Karpenter alongside Cluster Autoscaler

Add Karpenter to your `eks-addons` module call while CA is still running.
Both can coexist briefly during cut-over.

```hcl
module "eks_addons" {
  # ...existing config...

  enable_karpenter    = true
  karpenter_version   = "0.37.0"
  karpenter_namespace = "kube-system"
}
```

Apply and confirm Karpenter pods are running:

```bash
terraform apply
kubectl get pods -n kube-system -l app.kubernetes.io/name=karpenter
```

### Step 2 — Create NodePool and EC2NodeClass

Create the Karpenter node provisioning configuration. Apply these after
`terraform apply` completes (Karpenter CRDs are installed by the Helm release):

```yaml
# ec2nodeclass.yaml
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: AL2
  role: "<node_group_role_arn from EKS module outputs>"
  subnetSelectorTerms:
    - tags:
        kubernetes.io/cluster/<cluster_name>: owned
  securityGroupSelectorTerms:
    - tags:
        kubernetes.io/cluster/<cluster_name>: owned
  tags:
    Environment: prod
    ManagedBy: karpenter
```

```yaml
# nodepool.yaml
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      nodeClassRef:
        name: default
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ["m5.xlarge", "m5a.xlarge", "m6i.xlarge", "m6a.xlarge"]
  limits:
    cpu: "100"
    memory: "400Gi"
  disruption:
    consolidationPolicy: WhenUnderutilized
    expireAfter: 720h
```

```bash
kubectl apply -f ec2nodeclass.yaml
kubectl apply -f nodepool.yaml
```

### Step 3 — Scale down Cluster Autoscaler

```bash
kubectl scale deployment cluster-autoscaler -n kube-system --replicas=0
```

Verify Karpenter is provisioning nodes by watching for new node creation:

```bash
kubectl get nodes -w
```

### Step 4 — Disable Cluster Autoscaler IRSA

Once Karpenter is confirmed healthy, remove the CA IRSA role from your
EKS module and disable CA in eks-addons:

```hcl
module "eks" {
  # ...
  enable_cluster_autoscaler_irsa = false  # was true
}
```

```bash
terraform apply
```

This destroys `${cluster_name}-cluster-autoscaler` IAM role. Confirm Karpenter
nodes continue to scale correctly.

### Step 5 — Remove node group scaling limits (optional)

With Karpenter managing provisioning, the EKS managed node groups only need to
keep 1–2 ON_DEMAND nodes for system pods. Reduce `max_size`:

```hcl
node_groups = {
  system = {
    instance_types = ["m5.large"]
    capacity_type  = "ON_DEMAND"
    min_size       = 1
    max_size       = 2   # Karpenter handles the rest
    labels         = { "karpenter.sh/provisioner-name" = "default" }
    taints = [{
      key    = "CriticalAddonsOnly"
      value  = "true"
      effect = "NO_SCHEDULE"
    }]
  }
}
```

---

## Rollback

If Karpenter is misbehaving, revert to Cluster Autoscaler:

```bash
# Scale CA back up
kubectl scale deployment cluster-autoscaler -n kube-system --replicas=1

# Delete Karpenter NodePool to stop new provisioning
kubectl delete nodepool default
```

In Terraform:

```hcl
module "eks" {
  enable_cluster_autoscaler_irsa = true
}

module "eks_addons" {
  enable_karpenter = false
}
```

```bash
terraform apply
```

---

## State Import Notes

The `aws_sqs_queue.karpenter` and `aws_cloudwatch_event_rule.*` resources are
created fresh by `enable_karpenter = true`. No state import is required unless
you previously created these resources manually — in that case, import them
before applying:

```bash
terraform import 'module.eks_addons.aws_sqs_queue.karpenter[0]' <queue_url>
```
