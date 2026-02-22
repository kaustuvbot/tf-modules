locals {
  # Naming configuration based on cloud provider
  separator = var.cloud_provider == "gcp" ? "-" : "-"

  # GCP names must be lowercase
  name_parts = compact([
    var.cloud_provider == "gcp" ? lower(var.project) : var.project,
    var.cloud_provider == "gcp" ? lower(var.environment) : var.environment,
    var.cloud_provider == "gcp" ? lower(var.component) : var.component,
    var.cloud_provider == "gcp" ? lower(var.suffix) : var.suffix,
  ])

  # Standard resource name
  resource_name = join(local.separator, local.name_parts)

  # Short name variant (project-env) for use in constrained contexts
  short_name = join(local.separator, compact([
    var.cloud_provider == "gcp" ? lower(var.project) : var.project,
    var.cloud_provider == "gcp" ? lower(var.environment) : var.environment,
  ]))
}
