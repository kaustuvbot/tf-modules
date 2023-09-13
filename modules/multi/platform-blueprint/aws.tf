# AWS Stack Composition for Platform Blueprint
# Wires vpc + eks + logging into a coherent stack

module "aws_stack" {
  count  = local.is_aws ? 1 : 0
  source = "./aws-stack"

  project            = var.project
  environment        = var.environment
  region             = var.aws_config.region
  vpc_cidr           = var.aws_config.vpc_cidr
  availability_zones = var.aws_config.availability_zones
  eks_version        = var.aws_config.eks_version
  enable_nat_gateway = var.aws_config.enable_nat_gateway
  tags               = local.common_tags
}
