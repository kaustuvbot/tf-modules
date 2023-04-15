# Retrieve current AWS account and caller information.
# These data sources provide runtime context for tagging,
# naming, and cross-account validation.

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
