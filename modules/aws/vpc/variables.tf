variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "The vpc_cidr must be a valid CIDR block (e.g., 10.0.0.0/16)."
  }

  validation {
    condition     = tonumber(split("/", var.vpc_cidr)[1]) >= 16 && tonumber(split("/", var.vpc_cidr)[1]) <= 24
    error_message = "The VPC CIDR prefix must be between /16 and /24."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project" {
  description = "Project name for resource naming and tagging"
  type        = string

  validation {
    condition     = length(var.project) >= 2 && length(var.project) <= 32
    error_message = "Project name must be between 2 and 32 characters."
  }
}

variable "availability_zones" {
  description = "List of availability zones to use for subnets"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 1 && length(var.availability_zones) <= 3
    error_message = "You must specify between 1 and 3 availability zones."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT gateway(s) for private subnets"
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway for all AZs (cost saving for non-prod)"
  type        = bool
  default     = true
}

variable "enable_ecr_vpc_endpoints" {
  description = "Create VPC Interface Endpoints for ECR API and ECR DKR. Allows EKS nodes to pull container images without traversing NAT or the internet."
  type        = bool
  default     = false
}

variable "enable_s3_vpc_endpoint" {
  description = "Create a VPC Gateway Endpoint for S3. Reduces data transfer costs and avoids internet routing for S3 traffic from private subnets."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to all VPC resources"
  type        = map(string)
  default     = {}
}

variable "enable_ssm_vpc_endpoints" {
  description = "Create VPC Interface Endpoints for AWS Systems Manager (ssm, ssmmessages, ec2messages). Required to manage private EC2 instances via Session Manager without internet access."
  type        = bool
  default     = false
}

variable "enable_route53_health_check" {
  description = "Create a Route53 health check targeting the VPC's primary public endpoint. Used for DNS failover routing."
  type        = bool
  default     = false
}

variable "route53_health_check_fqdn" {
  description = "FQDN to health-check. Required when enable_route53_health_check=true."
  type        = string
  default     = null
}

variable "route53_health_check_port" {
  description = "Port to health-check. Defaults to 443."
  type        = number
  default     = 443
}

variable "route53_health_check_type" {
  description = "Health check protocol: HTTP, HTTPS, or TCP"
  type        = string
  default     = "HTTPS"

  validation {
    condition     = contains(["HTTP", "HTTPS", "TCP"], var.route53_health_check_type)
    error_message = "route53_health_check_type must be HTTP, HTTPS, or TCP."
  }
}
