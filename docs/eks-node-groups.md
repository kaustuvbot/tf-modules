# EKS Node Groups Guide

This guide covers node group configuration patterns, instance type selection,
SPOT capacity management, disk sizing, and taint-based scheduling as implemented
in the `modules/aws/eks` module.

---

## Node Group Object Shape

```hcl
node_groups = {
  general = {
    instance_types = ["m5.xlarge", "m5a.xlarge", "m6i.xlarge"]
    desired_size   = 3
    min_size       = 1
    max_size       = 10
    capacity_type  = "SPOT"       # ON_DEMAND | SPOT
    ami_type       = "AL2_x86_64" # AL2_x86_64 | AL2_ARM_64 | BOTTLEROCKET_x86_64 | CUSTOM
    disk_size      = 50           # GB, applied via launch template block_device_mappings
    labels         = { role = "general" }
    taints         = []
  }
}
```

---

## Instance Type Selection

### General-purpose workloads

| Family | vCPU | Mem | Notes |
|--------|------|-----|-------|
| `m5.xlarge` | 4 | 16 GB | Baseline, always available |
| `m5a.xlarge` | 4 | 16 GB | AMD variant, ~10% cheaper |
| `m6i.xlarge` | 4 | 16 GB | 3rd-gen Intel, 15% better perf/$ than m5 |
| `m6a.xlarge` | 4 | 16 GB | 3rd-gen AMD, cheapest general-purpose SPOT |

Use at least one from each family when configuring SPOT node groups. The capacity
pools are independent — multiple families means lower interruption probability.

### Compute-optimised (CPU-heavy workloads)

Use `c5`, `c5a`, `c6i`, `c6a`. Match `xlarge` and `2xlarge` sizes together
to keep pod scheduling predictable across instance types.

### Memory-optimised (caches, databases, Spark)

Use `r5`, `r5a`, `r6i`. Avoid mixing `r5.large` (16 GB) with `r5.2xlarge`
(64 GB) in the same node group — the scheduler sees them as equivalent and
may pack large pods onto the smaller node.

### ARM / Graviton

Set `ami_type = "AL2_ARM_64"` and use `m6g`, `c6g`, or `r6g` families.
Up to 40% cost reduction for compatible workloads. Requires container images
built for `linux/arm64`.

---

## SPOT Instance Best Practices

### Minimum 2 instance types (enforced by validation)

The module validation block rejects SPOT node groups with a single instance
type. Use 3+ types from at least 2 families:

```hcl
instance_types = ["m5.xlarge", "m5a.xlarge", "m6i.xlarge", "m6a.xlarge"]
```

### Enable Node Termination Handler

Always enable `enable_node_termination_handler = true` in the `eks-addons`
module when any node group uses `capacity_type = "SPOT"`. Without it, SPOT
interruptions terminate the node without draining pods, causing abrupt
workload failures.

### Pair SPOT with Pod Disruption Budgets

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: myapp
```

### Mixed ON_DEMAND + SPOT via separate node groups

```hcl
node_groups = {
  # Critical workloads on ON_DEMAND
  system = {
    instance_types = ["m5.large"]
    capacity_type  = "ON_DEMAND"
    min_size       = 2
    max_size       = 4
    labels         = { workload-type = "system" }
    taints = [{
      key    = "workload-type"
      value  = "system"
      effect = "NO_SCHEDULE"
    }]
  }

  # Batch / stateless on SPOT
  workers = {
    instance_types = ["m5.xlarge", "m5a.xlarge", "m6i.xlarge"]
    capacity_type  = "SPOT"
    min_size       = 0
    max_size       = 20
    labels         = { workload-type = "batch" }
  }
}
```

---

## Disk Sizing

The `disk_size` field is wired into the launch template as a `gp3` EBS root
volume (encrypted by default, satisfying CIS Benchmark 5.1.1).

| Workload | Recommended Size | Reason |
|----------|-----------------|--------|
| Standard pods | 50 GB (default) | OS + container images + ephemeral storage |
| Image-heavy CI runners | 100 GB | Multiple large images cached simultaneously |
| ML / data science | 200 GB | Large model artefacts and dataset downloads |
| Bottlerocket | 20–30 GB | Minimal OS, images stored in separate data volume |

**Why gp3?** gp3 provides 3,000 IOPS and 125 MB/s baseline at no extra cost
versus gp2 (which charges for provisioned IOPS above 100). For node groups,
this translates to faster image pulls and `etcd`-like workloads on the root
device.

---

## Taint-Based Scheduling

Taints reserve node groups for specific workload classes. Add a matching
`tolerations` block to the pod spec or Helm values.

### GPU node group example

```hcl
gpu = {
  instance_types = ["g4dn.xlarge"]
  capacity_type  = "ON_DEMAND"
  ami_type       = "AL2_x86_64_GPU"
  labels         = { accelerator = "nvidia" }
  taints = [{
    key    = "nvidia.com/gpu"
    value  = "true"
    effect = "NO_SCHEDULE"
  }]
}
```

### Spot-only taint (evict on interruption faster)

```hcl
taints = [{
  key    = "spot"
  value  = "true"
  effect = "PREFER_NO_SCHEDULE"
}]
```

`PREFER_NO_SCHEDULE` avoids scheduling non-tolerating pods on SPOT nodes
when ON_DEMAND capacity is available, without hard-blocking them.

---

## Node Labels Convention

| Label | Example Values | Purpose |
|-------|---------------|---------|
| `role` | `system`, `worker`, `gpu` | Broad workload affinity |
| `workload-type` | `batch`, `serving`, `ci` | Fine-grained affinity |
| `capacity-type` | `spot`, `on-demand` | Topology-aware scheduling |
| `team` | `platform`, `data` | Chargeback via cost allocation |

Labels are set at the Terraform level (stable) and at the kubelet level
(applied at node registration). Do not confuse with Kubernetes node labels
set by the cluster autoscaler or Karpenter (dynamic).

---

## Interaction with Karpenter

When `enable_karpenter = true` in the `eks-addons` module, Karpenter manages
its own node provisioning via `NodePool` and `EC2NodeClass` resources. In this
case:

- Set `min_size = 1`, `max_size = 1` for the EKS managed node groups (keep
  one ON_DEMAND node for system pods).
- Do not set `enable_cluster_autoscaler_irsa = true` simultaneously with
  Karpenter — they will conflict over ASG scaling.
- See [karpenter-migration.md](./karpenter-migration.md) for the migration path.
