locals {
  gcp = var.cloud == "gcp" ? var.gcp_config : null
}

module "gcp_vpc" {
  source = "../../gcp/vpc-network"

  count = var.cloud == "gcp" ? 1 : 0

  project     = local.gcp.project
  environment = var.environment

  subnets = {
    "main" = {
      region        = local.gcp.region
      ip_cidr_range = local.gcp.vpc_cidr
    }
  }

  enable_cloud_nat = true
  nat_region       = local.gcp.region

  labels = var.tags
}

module "gcp_iam" {
  source = "../../gcp/iam"

  count = var.cloud == "gcp" ? 1 : 0

  project     = local.gcp.project
  environment = var.environment

  workload_identity_enabled = true
  workload_identity_pool    = "${var.project}-pool"

  labels = var.tags
}

module "gcp_gke" {
  source = "../../gcp/gke"

  count = var.cloud == "gcp" ? 1 : 0

  project     = local.gcp.project
  environment = var.environment
  location    = local.gcp.region

  network_id    = module.gcp_vpc[0].network_id
  subnetwork_id = module.gcp_vpc[0].subnet_ids["main"]

  enable_private_nodes      = local.gcp.enable_private_nodes
  workload_identity_enabled = true

  node_pools = {
    "default" = {
      machine_type = "e2-standard-2"
      node_count   = 3
    }
  }

  labels = var.tags
}
