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
  # Also requires public subnets to exist (NAT sits in a public subnet)
  nat_gateway_count = (
    var.enable_nat_gateway && local.public_subnet_count > 0
    ? (var.single_nat_gateway ? 1 : local.az_count)
    : 0
  )

  # Map of private subnet index → route table index.
  # When single_nat_gateway=true all private subnets share route table [0].
  # When single_nat_gateway=false each AZ gets its own route table.
  # This map is used by aws_route_table_association.private to avoid
  # embedding conditional logic inline in the resource for_each argument.
  private_subnet_route_table_index = {
    for i in range(local.private_subnet_count) :
    i => var.single_nat_gateway ? 0 : i
  }
}
