resource "google_compute_router_nat" "this" {
  count = var.enable_cloud_nat ? 1 : 0

  name   = "nat-${local.name_prefix}"
  router = google_compute_router.this[0].name
  region = var.nat_region

  nat_ip_allocate_option = var.nat_ip_allocate_option
  nat_ips                = var.nat_ips

  source_subnetwork_ip_ranges_to_nat = var.nat_source_subnets

  dynamic "log_config" {
    for_each = var.enable_nat_logging ? [1] : []
    content {
      enable = true
      filter = "ALL"
    }
  }
}

resource "google_compute_router" "this" {
  count = var.enable_cloud_nat || var.enable_private_service_access ? 1 : 0

  name    = "router-${local.name_prefix}"
  network = google_compute_network.this.id
  region  = var.nat_region

  bgp {
    asn = var.bgp_asn
  }
}

resource "google_compute_global_forwarding_rule" "private_service_access" {
  count = var.enable_private_service_access ? 1 : 0

  name                  = "fwd-psa-${local.name_prefix}"
  network               = google_compute_network.this.id
  target                = google_compute_global_network_endpoint_group.this[0].id
  load_balancing_scheme = "INTERNAL"
}

resource "google_compute_network_endpoint_group" "this" {
  count = var.enable_private_service_access ? 1 : 0

  name                  = "neg-psa-${local.name_prefix}"
  network_endpoint_type = "PRIVATE_SERVICE_ACCESS"
  network               = google_compute_network.this.id
}
