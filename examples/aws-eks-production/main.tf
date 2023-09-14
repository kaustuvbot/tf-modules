# Production-hardened AWS EKS example
# Features: private nodes, IMDSv2, encrypted disks, Karpenter, SSM endpoints

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source = "../../modules/aws/vpc"

  project            = var.project
  environment        = var.environment
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = var.availability_zones
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_ssm_vpc_endpoints = true
  enable_s3_vpc_endpoint   = true
  enable_ecr_vpc_endpoints = true

  tags = local.tags
}

module "eks" {
  source = "../../modules/aws/eks"

  project            = var.project
  environment        = var.environment
  cluster_version    = "1.29"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  region             = var.region

  # Security hardening
  cluster_endpoint_public_access       = false
  cluster_endpoint_private_access      = true
  enable_secrets_encryption            = true

  node_groups = {
    system = {
      instance_types = ["m6i.large"]
      capacity_type  = "ON_DEMAND"
      min_size       = 2
      max_size       = 4
      desired_size   = 2
      disk_size      = 50
      # IMDSv2 enforced via launch template
    }
    workload = {
      instance_types = ["m6i.xlarge", "m6i.2xlarge"]
      capacity_type  = "SPOT"
      min_size       = 0
      max_size       = 20
      desired_size   = 2
      disk_size      = 100
    }
  }

  tags = local.tags
}

module "eks_addons" {
  source = "../../modules/aws/eks-addons"

  project                = var.project
  environment            = var.environment
  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_certificate_authority_data
  region                 = var.region
  oidc_provider_arn      = module.eks.oidc_provider_arn
  oidc_provider_url      = module.eks.oidc_provider_url
  vpc_id                 = module.vpc.vpc_id

  enable_alb_controller           = true
  enable_external_dns             = true
  enable_cert_manager             = true
  enable_karpenter                = true
  enable_node_termination_handler = true

  tags = local.tags
}

locals {
  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Example     = "aws-eks-production"
  }
}
