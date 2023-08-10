terraform {
  required_version = ">= 1.4.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
  }

  backend "s3" {
    # bucket         = "<project>-prod-tfstate-<account-id>"
    # key            = "prod/platform/terraform.tfstate"
    # region         = "us-east-1"
    # dynamodb_table = "<project>-prod-tflock"
    # encrypt        = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}

locals {
  environment = "prod"
}

# -----------------------------------------------------------------------------
# Encryption
# -----------------------------------------------------------------------------

module "kms" {
  source = "../../modules/aws/kms"

  project     = var.project
  environment = local.environment

  enable_logs_key    = true
  enable_state_key   = true
  enable_general_key = true
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------

module "vpc" {
  source = "../../modules/aws/vpc"

  project     = var.project
  environment = local.environment

  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = true
  single_nat_gateway   = false  # per-AZ NAT in prod for HA

  enable_flow_logs                    = true
  flow_logs_destination               = "cloud-watch-logs"
  flow_logs_cloudwatch_log_group_name = "/aws/${var.project}/prod/vpc-flow-logs"
}

# -----------------------------------------------------------------------------
# Kubernetes
# -----------------------------------------------------------------------------

module "eks" {
  source = "../../modules/aws/eks"

  project     = var.project
  environment = local.environment

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  cluster_version        = var.eks_cluster_version
  kms_key_arn            = module.kms.general_key_arn
  endpoint_public_access = false  # private cluster in prod
  imdsv2_required        = true

  node_groups = {
    system = {
      instance_types = ["m5.large"]
      min_size       = 2
      max_size       = 6
      desired_size   = 2
    }
  }
}

module "eks_addons" {
  source = "../../modules/aws/eks-addons"

  project     = var.project
  environment = local.environment

  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_certificate_authority_data
  region                 = var.region
  oidc_provider_arn      = module.eks.oidc_provider_arn
  oidc_provider_url      = module.eks.oidc_provider_url
  vpc_id                 = module.vpc.vpc_id

  enable_alb_controller = true
  enable_cert_manager   = true
}

# -----------------------------------------------------------------------------
# Monitoring
# -----------------------------------------------------------------------------

module "monitoring" {
  source = "../../modules/aws/monitoring"

  project     = var.project
  environment = local.environment

  cluster_name          = module.eks.cluster_name
  alarm_email_addresses = var.alarm_email_addresses
}

