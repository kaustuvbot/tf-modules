# GCP provider configuration baseline.
# Each module under modules/gcp/ inherits these constraints.
# Callers must configure the google provider in their root module.
#
# Recommended provider block for consumers:
#
#   provider "google" {
#     project = var.project_id
#     region  = var.region
#   }
#
#   provider "google-beta" {
#     project = var.project_id
#     region  = var.region
#   }
#
# No provider block is declared here — modules must not configure providers.
# Module-level provider requirements are declared in versions.tf.
