locals {
  name_prefix = "${var.project}-${var.environment}"

  default_labels = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }

  labels = merge(local.default_labels, var.labels)
}

resource "google_service_account" "this" {
  for_each = var.service_accounts

  account_id   = "${each.key}-${local.name_prefix}"
  display_name = each.value.display_name
  description  = each.value.description

  labels = local.labels
}

resource "google_project_iam_member" "this" {
  for_each = var.project_roles

  project = var.project
  role    = each.value.role
  member  = each.value.member
}

resource "google_project_iam_binding" "this" {
  for_each = var.project_bindings

  project = var.project
  role    = each.value.role
  members = each.value.members
}

resource "google_service_account_iam_member" "workload_identity" {
  for_each = var.workload_identity_enabled ? toset(var.service_accounts_keys) : []

  service_account_id = "projects/${var.project}/serviceAccounts/${var.project}-${var.environment}-${each.value}@${var.project}.iam.gserviceaccount.com"
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/projects/${var.project}/locations/global/workloadPools/${var.workload_identity_pool}"
}
