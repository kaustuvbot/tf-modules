locals {
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "vpc"
    },
    var.tags,
  )

  az_count             = length(var.availability_zones)
  public_subnet_count  = length(var.public_subnet_cidrs)
  private_subnet_count = length(var.private_subnet_cidrs)

  # NAT gateway count: 0 if disabled, 1 if single, or per-AZ
  nat_gateway_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : local.az_count) : 0
}
