# -----------------------------------------------------------------------------
# Example: AWS Complete Stack
# -----------------------------------------------------------------------------
# Demonstrates how to compose the AWS modules into a full environment:
#   VPC → EKS → EKS add-ons → Monitoring
#
# Not intended for production use as-is. Adjust variables for your needs.
# -----------------------------------------------------------------------------

module "vpc" {
  source = "../../modules/aws/vpc"

  project     = var.project
  environment = var.environment
  region      = var.region

  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["${var.region}a", "${var.region}b", "${var.region}c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = var.environment != "prod"

  tags = var.tags
}

module "eks" {
  source = "../../modules/aws/eks"

  project     = var.project
  environment = var.environment

  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  cluster_version = "1.27"

  node_groups = {
    general = {
      instance_types = ["m5.large"]
      min_size       = 2
      max_size       = 5
      desired_size   = 2
    }
  }

  tags = var.tags
}

module "eks_addons" {
  source = "../../modules/aws/eks-addons"

  project     = var.project
  environment = var.environment

  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_certificate_authority_data
  oidc_provider_arn      = module.eks.oidc_provider_arn
  oidc_provider_url      = module.eks.oidc_provider_url
  vpc_id                 = module.vpc.vpc_id
  region                 = var.region

  enable_prometheus      = var.enable_observability
  enable_loki            = var.enable_observability

  tags = var.tags
}

module "monitoring" {
  source = "../../modules/aws/monitoring"

  project     = var.project
  environment = var.environment
  region      = var.region

  cluster_name          = module.eks.cluster_name
  alarm_email_addresses = var.alarm_email_addresses

  tags = var.tags
}
