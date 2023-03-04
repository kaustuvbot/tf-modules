# Core naming module
# Generates consistent resource names across cloud providers.

locals {
  separator = "-"
  name_parts = compact([
    var.project,
    var.environment,
    var.component,
    var.suffix,
  ])
  resource_name = join(local.separator, local.name_parts)
}
