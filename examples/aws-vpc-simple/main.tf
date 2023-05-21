provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "../../modules/aws/vpc"

  project     = "example"
  environment = "dev"

  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Example = "aws-vpc-simple"
  }
}
