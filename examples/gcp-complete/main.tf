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

  network_name = "complete-vpc"

  subnets = {
    "us-central1" = {
      "system" = {
        ip_cidr_range = "10.0.1.0/24"
      }
      "workloads" = {
        ip_cidr_range = "10.0.2.0/24"
      }
    }
  }

  secondary_ranges = {
    "system" = [
      {
        range_name    = "pods-system"
        ip_cidr_range = "10.1.0.0/16"
      },
      {
        range_name    = "services-system"
        ip_cidr_range = "10.2.0.0/16"
      }
    ]
    "workloads" = [
      {
        range_name    = "pods-workloads"
        ip_cidr_range = "10.3.0.0/16"
      },
      {
        range_name    = "services-workloads"
        ip_cidr_range = "10.4.0.0/16"
      }
    ]
  }

  enable_cloud_nat = true

  labels = {
    Example = "gcp-complete"
  }
}

module "kms" {
  source = "../../modules/gcp/cloudkms"

  project      = var.project_id
  environment = var.environment

  rotation_period = "7776000s"  # 90 days

  labels = {
    Example = "gcp-complete"
  }
}

module "storage" {
  source = "../../modules/gcp/storage"

  project      = var.project_id
  environment = var.environment

  bucket_name_suffix = "data"

  versioning_enabled              = true
  uniform_bucket_level_access    = true

  lifecycle_rules = [
    {
      action_type = "SetStorageClass"
      storage_class = "NEARLINE"
      age          = 30
    }
  ]

  kms_key_name = module.kms.crypto_key_id

  labels = {
    Example = "gcp-complete"
  }
}

module "iam" {
  source = "../../modules/gcp/iam"

  project = var.project_id

  service_accounts = {
    "gke-workload" = {
      display_name = "GKE Workload Identity SA"
      description  = "Service account for GKE workloads"
    }
  }

  labels = {
    Example = "gcp-complete"
  }
}

module "gke" {
  source = "../../modules/gcp/gke"

  project        = var.project_id
  environment  = var.environment
  location     = var.region

  network_id    = module.vpc.network_id
  subnetwork_id = module.vpc.subnetwork_ids["system"]

  enable_private_nodes     = true
  enable_private_endpoint = true
  enable_network_policy   = true

  workload_identity_enabled = true

  enable_database_encryption = true
  database_encryption_key = module.kms.crypto_key_id

  node_pools = {
    system = {
      machine_type   = "e2-standard-4"
      node_count   = 3
      min_node_count = 3
      max_node_count = 10
      preemptible  = false
    }
    workloads = {
      machine_type   = "e2-standard-2"
      node_count   = 2
      min_node_count = 0
      max_node_count = 20
      preemptible  = true
    }
  }

  labels = {
    Example = "gcp-complete"
  }
}
