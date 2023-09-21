# AWS VPC Module
#
# Creates a VPC with public and private subnets across multiple
# availability zones. Supports optional NAT gateway for private
# subnet internet access.

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-vpc"
  })
}

# --- Public Subnets ---

resource "aws_subnet" "public" {
  count = local.public_subnet_count

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-public-${element(var.availability_zones, count.index)}"
    Tier = "public"
  })
}

# --- Private Subnets ---

resource "aws_subnet" "private" {
  count = local.private_subnet_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-private-${element(var.availability_zones, count.index)}"
    Tier = "private"
  })
}

# --- Internet Gateway ---

resource "aws_internet_gateway" "this" {
  count = local.public_subnet_count > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-igw"
  })
}

# --- NAT Gateway ---

resource "aws_eip" "nat" {
  count = local.nat_gateway_count

  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-nat-eip-${count.index}"
  })
}

resource "aws_nat_gateway" "this" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-nat-${count.index}"
  })

  depends_on = [aws_internet_gateway.this]
}

# --- Public Route Table ---

resource "aws_route_table" "public" {
  count = local.public_subnet_count > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-public-rt"
    Tier = "public"
  })
}

resource "aws_route" "public_internet" {
  count = local.public_subnet_count > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {
  count = local.public_subnet_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# --- Private Route Tables ---

resource "aws_route_table" "private" {
  count = local.private_subnet_count > 0 ? (var.single_nat_gateway ? 1 : local.az_count) : 0

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-private-rt-${count.index}"
    Tier = "private"
  })
}

resource "aws_route" "private_nat" {
  count = local.nat_gateway_count

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}

resource "aws_route_table_association" "private" {
  for_each = local.private_subnet_route_table_index

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.value].id
}

# -----------------------------------------------------------------------------
# VPC Gateway Endpoints
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# VPC Interface Endpoints (ECR)
# -----------------------------------------------------------------------------

resource "aws_vpc_endpoint" "ecr_api" {
  count = var.enable_ecr_vpc_endpoints ? 1 : 0

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-ecr-api-endpoint"
  })
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.enable_ecr_vpc_endpoints ? 1 : 0

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-ecr-dkr-endpoint"
  })
}

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_vpc_endpoint ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-s3-endpoint"
  })
}
