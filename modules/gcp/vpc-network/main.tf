locals {
  name_prefix = "${var.project}-${var.environment}"

  default_labels = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }

  labels = merge(local.default_labels, var.labels)
}

resource "google_compute_network" "this" {
  name                    = "vpc-${local.name_prefix}"
  auto_create_subnetworks = false
  routing_mode           = var.routing_mode
  mtu                    = var.mtu

  labels = local.labels

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_subnetwork" "this" {
  for_each = var.subnets

  name                     = "subnet-${local.name_prefix}-${each.key}"
  network                 = google_compute_network.this.id
  region                 = each.value.region
  ip_cidr_range          = each.value.ip_cidr_range
  private_ip_google_access = each.value.private_ip_google_access

  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ranges != null ? each.value.secondary_ranges : {}
    content {
      range_name    = secondary_ip_range.key
      ip_cidr_range = secondary_ip_range.value
    }
  }

  labels = merge(local.labels, { name = each.key })

  lifecycle {
    create_before_destroy = true
  }
}
