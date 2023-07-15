package terraform.required_tags

# Required tags that every taggable AWS resource must have.
# This policy runs in soft-fail mode initially — violations are warnings, not blockers.

required_tags := {"Project", "Environment", "ManagedBy"}

# Resources that support tags (expand as modules grow)
taggable_resource_types := {
  "aws_vpc",
  "aws_subnet",
  "aws_internet_gateway",
  "aws_nat_gateway",
  "aws_eks_cluster",
  "aws_eks_node_group",
  "aws_iam_role",
  "aws_s3_bucket",
  "aws_kms_key",
  "aws_cloudwatch_log_group",
  "aws_cloudtrail",
  "aws_sns_topic",
  "aws_budgets_budget",
}

# Deny resources missing required tags
deny[msg] {
  resource := input.resource_changes[_]
  resource.type := taggable_resource_types[_]
  resource.change.after != null

  # Get the tags from the planned resource
  tags := resource.change.after.tags

  # Find any required tag that is missing
  missing_tag := required_tags[_]
  not tags[missing_tag]

  msg := sprintf(
    "Resource '%s' (%s) is missing required tag: %s",
    [resource.address, resource.type, missing_tag],
  )
}

# Warn about empty tag values
warn[msg] {
  resource := input.resource_changes[_]
  resource.type := taggable_resource_types[_]
  resource.change.after != null

  tags := resource.change.after.tags
  tag_key := required_tags[_]
  tags[tag_key] == ""

  msg := sprintf(
    "Resource '%s' (%s) has an empty value for required tag: %s",
    [resource.address, resource.type, tag_key],
  )
}
