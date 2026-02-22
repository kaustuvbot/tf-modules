locals {
  name_prefix = "${var.project}-${var.environment}"

  default_labels = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }

  labels = merge(local.default_labels, var.labels)
}

resource "google_storage_bucket" "this" {
  name          = "${local.name_prefix}-${var.bucket_name_suffix}"
  location      = var.location
  project       = var.project
  storage_class = var.storage_class

  versioning {
    enabled = var.versioning_enabled
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      action {
        type          = lifecycle_rule.value.action_type
        storage_class = lifecycle_rule.value.storage_class
      }
      condition {
        age                = lifecycle_rule.value.age
        created_before     = lifecycle_rule.value.created_before
        is_live            = lifecycle_rule.value.is_live
        matches_prefix     = lifecycle_rule.value.matches_prefix
        matches_suffix     = lifecycle_rule.value.matches_suffix
        num_newer_versions = lifecycle_rule.value.num_newer_versions
      }
    }
  }

  uniform_bucket_level_access = var.uniform_bucket_level_access

  dynamic "encryption" {
    for_each = var.kms_key_name != null ? [1] : []
    content {
      default_kms_key_name = var.kms_key_name
    }
  }

  dynamic "retention_policy" {
    for_each = var.retention_period_days != null ? [1] : []
    content {
      retention_period = var.retention_period_days
      is_locked        = var.retention_policy_locked
    }
  }

  labels = local.labels
}

resource "google_storage_bucket_iam_member" "viewer" {
  for_each = toset(var.viewer_members)

  bucket = google_storage_bucket.this.name
  role   = "roles/storage.objectViewer"
  member = each.value
}

resource "google_storage_bucket_iam_member" "editor" {
  for_each = toset(var.editor_members)

  bucket = google_storage_bucket.this.name
  role   = "roles/storage.objectAdmin"
  member = each.value
}
