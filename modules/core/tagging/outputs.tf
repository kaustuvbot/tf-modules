output "tags" {
  description = "Complete map of tags to apply to resources"
  value       = local.tags
}

output "default_tags" {
  description = "Only the default tags (without extra_tags merged)"
  value       = local.default_tags
}
