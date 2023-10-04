locals {
  name_prefix = "${var.project}-${var.environment}"

  default_labels = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }

  labels = merge(local.default_labels, var.labels)
}

resource "google_container_cluster" "this" {
  name     = "gke-${local.name_prefix}"
  location = var.location

  project = var.project

  remove_default_node_pool = true
  initial_node_count       = var.initial_node_count

  network    = var.network_id
  subnetwork = var.subnetwork_id

  enable_legacy_abac                       = false
  enable_shielded_nodes                    = var.enable_shielded_nodes
  enable_kubernetes_alpha                  = var.enable_kubernetes_alpha
  enable_private_nodes                     = var.enable_private_nodes
  enable_master_authorized_networks_config = var.master_authorized_networks_enabled

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  private_cluster_config {
    enable_private_endpoint = var.enable_private_endpoint
    enable_private_nodes    = var.enable_private_nodes

    master_ipv4_cidr_block = var.master_ipv4_cidr_block
  }

  workload_identity_config {
    workload_pool = "${var.project}.svc.id.goog"
  }

  network_policy {
    enabled = var.enable_network_policy
  }

  dynamic "binary_authorization" {
    for_each = var.enable_binary_authorization ? [1] : []
    content {
      evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
    }
  }

  dynamic "database_encryption" {
    for_each = var.enable_database_encryption ? [1] : []
    content {
      state    = "ENCRYPTED"
      key_name = var.database_encryption_key
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  timeouts {
    create = "30m"
    update = "30m"
  }

  labels = local.labels
}

resource "google_container_node_pool" "this" {
  for_each = var.node_pools

  name     = "nodepool-${local.name_prefix}-${each.key}"
  location = var.location
  cluster  = google_container_cluster.this.name

  node_count = each.value.node_count

  node_config {
    machine_type    = each.value.machine_type
    disk_type       = each.value.disk_type
    disk_size_gb    = each.value.disk_size_gb
    service_account = each.value.service_account
    preemptible     = each.value.preemptible

    labels = merge(local.labels, each.value.labels)

    shielded_instance_config {
      enable_secure_boot          = each.value.enable_secure_boot
      enable_integrity_monitoring = each.value.enable_integrity_monitoring
    }

    dynamic "workload_metadata_config" {
      for_each = var.workload_identity_enabled ? [1] : []
      content {
        mode = "GKE_METADATA"
      }
    }
  }

  autoscaling {
    min_node_count = each.value.min_node_count
    max_node_count = each.value.max_node_count
  }

  management {
    auto_repair  = each.value.auto_repair
    auto_upgrade = each.value.auto_upgrade
  }

  dynamic "upgrade_settings" {
    for_each = each.value.max_surge != null ? [1] : []
    content {
      max_surge       = each.value.max_surge
      max_unavailable = each.value.max_unavailable
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
