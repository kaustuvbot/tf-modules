# Core naming module
# Generates consistent resource names across cloud providers.
#
# Usage:
#   module "naming" {
#     source      = "../../modules/core/naming"
#     project     = "myplatform"
#     environment = "dev"
#     component   = "vpc"
#   }
#
# Outputs: resource_name = "myplatform-dev-vpc"
