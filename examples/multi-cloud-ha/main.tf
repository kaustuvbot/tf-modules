# Multi-Cloud HA Example
# Demonstrates deploying the same application to AWS, Azure, and GCP
# with Route53 DNS for global failover

provider "aws" {
  region = "us-east-1"
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

provider "google" {
  project = var.gcp_project_id
  region  = "us-central1"
}

# =============================================================================
# AWS Stack (Primary)
# =============================================================================

module "aws_vpc" {
  source = "../../modules/aws/vpc"

  project     = var.project
  environment = "prod"

  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Cloud   = "aws"
    Purpose = "primary"
  }
}

# =============================================================================
# Azure Stack (Secondary)
# =============================================================================

resource "azurerm_resource_group" "secondary" {
  name     = "${var.project}-secondary-rg"
  location = "eastus"
}

module "azure_vnet" {
  source = "../../modules/azure/vnet"

  project             = var.project
  environment       = "prod"
  resource_group_name = azurerm_resource_group.secondary.name
  location          = "eastus"

  address_space = ["10.1.0.0/16"]

  subnets = {
    "public" = {
      address_prefixes = ["10.1.1.0/24"]
    }
    "private" = {
      address_prefixes = ["10.1.10.0/24"]
    }
  }

  tags = {
    Cloud   = "azure"
    Purpose = "secondary"
  }
}

# =============================================================================
# GCP Stack (Tertiary)
# =============================================================================

module "gcp_vpc" {
  source = "../../modules/gcp/vpc-network"

  project      = var.gcp_project_id
  environment = "prod"
  region      = "us-central1"

  network_name = "ha-vpc"

  subnets = {
    "us-central1" = {
      "main" = {
        ip_cidr_range = "10.2.1.0/24"
      }
    }
  }

  enable_cloud_nat = true

  labels = {
    Cloud   = "gcp"
    Purpose = "tertiary"
  }
}

# =============================================================================
# Route53 Health Checks and Failover Records
# =============================================================================

resource "aws_route53_health_check" "primary" {
  fqdn              = "primary.${var.domain}"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Cloud = "aws"
  }
}

resource "aws_route53_health_check" "secondary" {
  fqdn              = "secondary.${var.domain}"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Cloud = "azure"
  }
}

resource "aws_route53_health_check" "tertiary" {
  fqdn              = "tertiary.${var.domain}"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Cloud = "gcp"
  }
}

resource "aws_route53_record" "primary" {
  zone_id = var.route53_zone_id
  name    = "primary.${var.domain}"
  type    = "A"

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier  = "primary"
  health_check_id = aws_route53_health_check.primary.id

  alias {
    name                   = "primary-alb.us-east-1.elb.amazonaws.com"
    zone_id                = "Z35SXDOWRQ4JHG"  # us-east-1
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "secondary" {
  zone_id = var.route53_zone_id
  name    = "secondary.${var.domain}"
  type    = "A"

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier  = "secondary"
  health_check_id = aws_route53_health_check.secondary.id

  alias {
    name                   = "secondary-agw.eastus.cloudapp.azure.com"
    zone_id                = "AZURE_ZONE_ID"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "tertiary" {
  zone_id = var.route53_zone_id
  name    = "tertiary.${var.domain}"
  type    = "A"

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier  = "tertiary"
  health_check_id = aws_route53_health_check.tertiary.id

  alias {
    name                   = "tertiary-lb.us-central1.loadbalancer.googleapis.com"
    zone_id                = "GCP_ZONE_ID"
    evaluate_target_health = true
  }
}
