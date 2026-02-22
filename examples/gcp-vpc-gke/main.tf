provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

module "vpc" {
  source = "../../modules/gcp/vpc-network"

  project      = var.project_id
  environment = var.environment
  region      = var.region

  network_name = "example-vpc"

  subnets = {
    "us-central1" = {
      "example-primary" = {
        ip_cidr_range = "10.0.1.0/24"
      }
    }
  }

  secondary_ranges = {
    "example-primary" = [
      {
        range_name    = "pods"
        ip_cidr_range = "10.1.0.0/16"
      },
      {
        range_name    = "services"
        ip_cidr_range = "10.2.0.0/16"
      }
    ]
  }

  enable_cloud_nat = true

  labels = {
    Example = "gcp-vpc-gke"
  }
}

module "gke" {
  source = "../../modules/gcp/gke"

  project        = var.project_id
  environment   = var.environment
  location      = var.region

  network_id    = module.vpc.network_id
  subnetwork_id = module.vpc.subnetwork_ids["example-primary"]

  enable_private_nodes    = true
  enable_private_endpoint = true
  enable_network_policy  = true
  workload_identity_enabled = true

  node_pools = {
    default = {
      machine_type   = "e2-standard-2"
      node_count     = 3
      min_node_count = 3
      max_node_count = 10
    }
  }

  labels = {
    Example = "gcp-vpc-gke"
  }
}
