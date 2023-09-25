# -----------------------------------------------------------------------------
# Example: VPC + EKS + EKS Add-ons
# -----------------------------------------------------------------------------
# Demonstrates how the three core AWS modules wire together:
#
#   1. VPC module   → outputs subnet_ids and vpc_id
#   2. EKS module   → consumes VPC outputs; outputs OIDC provider and endpoints
#   3. eks-addons   → consumes EKS OIDC outputs to configure IRSA for each add-on
#
# This is a minimal example suitable for a development cluster. Adjust node
# group sizing and add-on selection for staging/prod workloads.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# 1. VPC
# -----------------------------------------------------------------------------

module "vpc" {
  source = "../../modules/aws/vpc"

  project     = var.project
  environment = var.environment

  availability_zones   = var.availability_zones
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  enable_s3_vpc_endpoint = true
}

# -----------------------------------------------------------------------------
# 2. EKS Cluster
# -----------------------------------------------------------------------------

module "eks" {
  source = "../../modules/aws/eks"

  project     = var.project
  environment = var.environment

  kubernetes_version = var.kubernetes_version
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids

  node_groups = {
    general = {
      instance_types = ["t3.medium", "t3a.medium"]
      desired_size   = 2
      min_size       = 1
      max_size       = 4
      capacity_type  = "SPOT"
      disk_size      = 50
    }
  }

  # Enforce IMDSv2 on all nodes (default true, shown explicitly for clarity)
  imdsv2_required                      = true
  metadata_http_put_response_hop_limit = 1

  # Enable IRSA role for Cluster Autoscaler if you prefer it over Karpenter
  enable_cluster_autoscaler_irsa = false
}

# -----------------------------------------------------------------------------
# 3. EKS Add-ons
# -----------------------------------------------------------------------------
# OIDC outputs from the EKS module flow directly into eks-addons so each
# add-on can create its own IRSA role without manual ARN copying.

module "eks_addons" {
  source = "../../modules/aws/eks-addons"

  project     = var.project
  environment = var.environment

  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_certificate_authority
  region                 = var.region
  vpc_id                 = module.vpc.vpc_id

  # OIDC outputs wired from the EKS module — no manual ARN copying required
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  # ALB Controller: always enabled; handles Ingress → ALB provisioning
  enable_alb_controller = true
  enable_waf_v2         = false

  # ExternalDNS: sync Ingress/Service hostnames to Route53
  enable_external_dns = var.route53_zone_id != ""
  route53_zone_ids    = var.route53_zone_id != "" ? [var.route53_zone_id] : []

  # cert-manager: automate TLS certificate issuance via Let's Encrypt
  enable_cert_manager = true

  # Node Termination Handler: required because the node group uses SPOT
  enable_node_termination_handler = true
}
