# Azure Security Hardening Guide

## Overview

This guide covers the security controls available across the Azure modules and recommended production settings.

---

## AKS

### Private Cluster

Disable the public API server endpoint entirely for production:

```hcl
module "aks" {
  # ...
  private_cluster_enabled = true
}
```

With a private cluster, the API server is only reachable from within the VNet or peered networks. Ensure your CI runner has network access via a self-hosted runner or Azure DevOps agent in the same VNet.

### Authorized IP Ranges (public clusters)

For non-private clusters, restrict access with a CIDR allowlist:

```hcl
module "aks" {
  # ...
  endpoint_public_access = true
  authorized_ip_ranges   = ["203.0.113.0/24"]
}
```

### Azure Policy Add-on

Enable OPA Gatekeeper-based policy enforcement:

```hcl
module "aks" {
  # ...
  azure_policy_enabled = true
}
```

Once enabled, assign Azure Policy initiatives (e.g., "Kubernetes cluster pod security baseline standards") via the Azure portal or `azurerm_resource_policy_assignment`.

### Workload Identity

Use Workload Identity instead of pod-level managed identities for fine-grained access control:

```hcl
module "aks" {
  # ...
  workload_identity_enabled = true
}
```

Then create a federated identity credential linking a Kubernetes service account to an Azure managed identity.

---

## Key Vault

### Network ACLs

Restrict Key Vault access to known subnets:

```hcl
module "kv" {
  # ...
  network_acls_default_action = "Deny"
  network_acls_bypass         = "AzureServices"
  network_acls_subnet_ids     = [module.vnet.subnet_ids["aks-system"]]
}
```

Setting `network_acls_default_action = "Deny"` blocks all traffic not matching an explicit rule. `AzureServices` bypass allows trusted Microsoft services (e.g., Azure Monitor, Backup) to still access the vault.

### Purge Protection

Purge protection is enabled by default (`purge_protection_enabled = true`). Do not disable this in production — it prevents permanent deletion of secrets before the soft-delete retention period expires.

---

## VNet

### Deny Inbound Internet

Each subnet can optionally block inbound internet traffic via an NSG rule:

```hcl
module "vnet" {
  # ...
  subnets = {
    aks-system = {
      address_prefixes      = ["10.10.1.0/24"]
      deny_inbound_internet = true   # default
    }
    public-ingress = {
      address_prefixes      = ["10.10.3.0/24"]
      deny_inbound_internet = false  # allow public traffic for ingress subnet
    }
  }
}
```

---

## Compliance Baseline

| Control | Module | Default | Recommended |
|---------|--------|---------|-------------|
| Private API server | `aks` | Off | On in prod |
| Azure Policy add-on | `aks` | Off | On |
| Workload Identity | `aks` | Off | On |
| Key Vault network ACLs | `key-vault` | Allow all | Deny + subnet allowlist |
| Purge protection | `key-vault` | On | On |
| Deny inbound internet | `vnet` | On per subnet | On |
| AKS diagnostic logs | `aks` | Off | On (Log Analytics) |
