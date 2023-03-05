terraform {
  required_version = ">= 1.4.0, < 2.0.0"

  # backend "s3" {
  #   bucket         = "<project>-terraform-state-<region>"
  #   key            = "prod/platform/terraform.tfstate"
  #   region         = "<region>"
  #   dynamodb_table = "<project>-terraform-lock"
  #   encrypt        = true
  # }
}

locals {
  environment = "prod"
  project     = var.project
}

module "naming" {
  source      = "../../modules/core/naming"
  project     = local.project
  environment = local.environment
}

module "tagging" {
  source      = "../../modules/core/tagging"
  project     = local.project
  environment = local.environment
  extra_tags  = var.extra_tags
}
