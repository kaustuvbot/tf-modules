# Core tagging module
# Provides a consistent tagging/labels interface for all cloud resources.
#
# Usage:
#   module "tagging" {
#     source      = "../../modules/core/tagging"
#     project     = "myplatform"
#     environment = "dev"
#     extra_tags  = { Team = "platform" }
#   }
#
# Outputs: tags = { Project = "myplatform", Environment = "dev", ManagedBy = "terraform", Team = "platform" }
