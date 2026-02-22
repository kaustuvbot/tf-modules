locals {
  name_prefix = "${var.project}-${var.environment}"

  default_labels = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }

  labels = merge(local.default_labels, var.labels)
}

resource "google_kms_key_ring" "this" {
  name     = "kr-${local.name_prefix}"
  location = var.location
  project  = var.project

  labels = local.labels
}

resource "google_kms_crypto_key" "this" {
  name     = "key-${local.name_prefix}"
  key_ring = google_kms_key_ring.this.id

  rotation_period = var.rotation_period
  version_template {
    algorithm        = var.key_algorithm
    protection_level = var.protection_level
  }

  lifecycle {
    prevent_destroy = true
  }

  labels = local.labels
}

resource "google_kms_crypto_key_iam_member" "key_admin" {
  for_each = toset(var.key_admin_service_accounts)

  crypto_key_id = google_kms_crypto_key.this.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${each.value}"
}

resource "google_kms_crypto_key_iam_member" "key_viewer" {
  for_each = toset(var.key_viewer_service_accounts)

  crypto_key_id = google_kms_crypto_key.this.id
  role          = "roles/cloudkms.viewer"
  member        = "serviceAccount:${each.value}"
}
