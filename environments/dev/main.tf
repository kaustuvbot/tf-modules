terraform {
  required_version = ">= 1.4.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
  }

  backend "s3" {
    # Configure via -backend-config or environment variables
    # bucket         = "<project>-dev-tfstate-<account-id>"
    # key            = "dev/platform/terraform.tfstate"
    # region         = "us-east-1"
    # dynamodb_table = "<project>-dev-tflock"
    # encrypt        = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

locals {
  environment = "dev"
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
  single_nat_gateway   = true  # single NAT for dev cost savings
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
  endpoint_public_access = true
  public_access_cidrs    = var.eks_public_access_cidrs

  node_groups = {
    general = {
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 1
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
}
