# Troubleshooting Guide

Common errors encountered when working with this module set, with root causes and fixes.

---

## Terraform / Provider

### Error: `Error acquiring the state lock`

**Cause:** A previous `terraform apply` was interrupted, leaving the DynamoDB lock held.
**Fix:**
```bash
terraform force-unlock <lock-id>
```
Find the lock ID in the error output. Only force-unlock if you are certain no
other apply is running.

---

### Error: `Provider produced inconsistent final plan`

**Cause:** A resource attribute computed after apply differs from what the plan showed.
Common with EKS node groups (launch template versions) and AKS upgrade fields.
**Fix:** Add the drifting attribute to `lifecycle.ignore_changes`. Document why.

---

### Error: `Error: creating S3 Bucket (…): BucketAlreadyOwnedByYou`

**Cause:** The state bucket already exists (e.g., from a previous bootstrap).
**Fix:** Import the existing bucket:
```bash
terraform import module.s3_state.aws_s3_bucket.this <bucket-name>
```

---

## EKS

### `kubectl` returns `error: You must be logged in to the server (Unauthorized)`

**Cause:** `aws-auth` ConfigMap does not include the current IAM role.
**Fix:**
```bash
aws eks update-kubeconfig --name <cluster-name> --region <region>
```
Ensure your IAM role is in `aws-auth`. The EKS module adds the apply role
automatically. If using a different role, add it via `aws_auth_roles` variable.

---

### ALB Controller pods in `CrashLoopBackOff`

**Cause 1:** IRSA role trust policy uses wrong namespace or service account name.
**Fix:** Verify the OIDC provider URL matches exactly. Check:
```bash
kubectl describe sa -n kube-system aws-load-balancer-controller
```

**Cause 2:** cert-manager CRDs not yet ready when ALB controller installs.
**Fix:** The `depends_on` in `eks-addons` ensures cert-manager installs first.
If installing manually, wait for cert-manager webhook to be ready.

---

### Karpenter not scaling up

**Cause 1:** No `NodePool` or `EC2NodeClass` resource defined (these are not created by the module — they are cluster resources).
**Fix:** Apply a `NodePool` CRD after the cluster is ready. See [karpenter-migration.md](karpenter-migration.md).

**Cause 2:** SQS interruption queue ARN not wired into Karpenter Helm values.
**Fix:** Check that `karpenter_version >= 0.34` and the queue URL is in the Helm values.

---

## Azure / AKS

### `Error: waiting for AKS Managed Cluster to be created: Code="SubnetIsFull"`

**Cause:** The AKS subnet CIDR is too small for the requested node count and pod CIDR.
**Fix:** Use a /22 or larger subnet for production AKS clusters. Azure CNI reserves
IPs per node based on `max_pods` setting (default 30 per node).

---

### `Error: A resource with the ID "…/privateDnsZones/…" already exists`

**Cause:** Terraform tries to create a private DNS zone that already exists in the subscription.
**Fix:** Import the existing zone:
```bash
terraform import module.private_dns.azurerm_private_dns_zone.this \
  "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Network/privateDnsZones/<zone>"
```

---

### AKS private cluster: `kubectl` cannot reach API server

**Cause:** You are connecting from outside the VNet. Private clusters have no public endpoint.
**Fix options:**
1. Use Azure Bastion or a jump VM inside the VNet
2. Use AKS `run-command` for one-off commands:
   ```bash
   az aks command invoke --resource-group <rg> --name <cluster> --command "kubectl get nodes"
   ```
3. Enable the `command` feature (enabled by default on private clusters)

---

## Terraform State

### State shows resources as missing after manual deletion

**Cause:** Resources deleted outside Terraform leave stale state entries.
**Fix:**
```bash
terraform state rm <resource-address>
```
Then re-import or let Terraform recreate.

---

### `terraform plan` shows unexpected replacement for EKS node groups

**Cause:** Launch template version changed (e.g., AMI update), triggering replacement.
**Fix:** If this is expected (AMI rotation), proceed. If unexpected, check:
- `custom_ami_id` variable — if set, changes force replacement
- `launch_template_version` in AWS console

To minimize disruption, use rolling node group updates:
```bash
aws eks update-nodegroup-version --cluster-name <name> --nodegroup-name <ng>
```

---

## CI/CD

### GitHub Actions `terraform plan` fails with `Error: No valid credential sources found`

**Cause:** OIDC trust policy is not configured or the GitHub Actions `id-token: write` permission is missing.
**Fix:**
1. Add `permissions: id-token: write` to the workflow job
2. Verify the IAM role trust policy includes the correct GitHub org/repo condition
3. Check `aws-actions/configure-aws-credentials` version is >= v4
