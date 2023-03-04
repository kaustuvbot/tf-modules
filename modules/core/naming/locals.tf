locals {
  # Naming configuration
  separator = "-"

  # Build name parts, filtering out empty strings
  name_parts = compact([
    var.project,
    var.environment,
    var.component,
    var.suffix,
  ])

  # Standard resource name
  resource_name = join(local.separator, local.name_parts)

  # Short name variant (project-env) for use in constrained contexts
  short_name = join(local.separator, compact([var.project, var.environment]))
}
