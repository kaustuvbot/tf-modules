# DynamoDB table for Terraform state locking.
#
# Uses PAY_PER_REQUEST billing to avoid provisioned capacity costs
# for a table that sees very low traffic. Optionally supports TTL
# to auto-expire stale lock entries.

resource "aws_dynamodb_table" "lock" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  dynamic "ttl" {
    for_each = var.enable_ttl ? [1] : []
    content {
      attribute_name = var.ttl_attribute
      enabled        = true
    }
  }

  tags = var.tags
}
