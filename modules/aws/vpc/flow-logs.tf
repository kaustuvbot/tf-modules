# -----------------------------------------------------------------------------
# VPC Flow Logs
# -----------------------------------------------------------------------------
# Captures all IP traffic to/from the VPC. Logs can be delivered to
# CloudWatch Logs or S3. Set flow_logs_destination to enable.
# -----------------------------------------------------------------------------

variable "enable_flow_logs" {
  description = "Enable VPC flow logs"
  type        = bool
  default     = false
}

variable "flow_logs_destination" {
  description = "Destination type for flow logs: cloud-watch-logs or s3"
  type        = string
  default     = "cloud-watch-logs"

  validation {
    condition     = contains(["cloud-watch-logs", "s3"], var.flow_logs_destination)
    error_message = "flow_logs_destination must be cloud-watch-logs or s3."
  }
}

variable "flow_logs_cloudwatch_log_group_name" {
  description = "CloudWatch log group name for flow logs. Required when flow_logs_destination=cloud-watch-logs."
  type        = string
  default     = null
}

variable "flow_logs_s3_bucket_arn" {
  description = "S3 bucket ARN for flow logs. Required when flow_logs_destination=s3."
  type        = string
  default     = null
}

variable "flow_logs_traffic_type" {
  description = "Type of traffic to capture (ACCEPT, REJECT, ALL)"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_logs_traffic_type)
    error_message = "flow_logs_traffic_type must be ACCEPT, REJECT, or ALL."
  }
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs && var.flow_logs_destination == "cloud-watch-logs" ? 1 : 0

  name = "${"${var.project}-${var.environment}"}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs && var.flow_logs_destination == "cloud-watch-logs" ? 1 : 0

  name = "${"${var.project}-${var.environment}"}-vpc-flow-logs-policy"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
      ]
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id       = aws_vpc.this.id
  traffic_type = var.flow_logs_traffic_type

  iam_role_arn    = var.flow_logs_destination == "cloud-watch-logs" ? aws_iam_role.flow_logs[0].arn : null
  log_destination = var.flow_logs_destination == "cloud-watch-logs" ? var.flow_logs_cloudwatch_log_group_name : var.flow_logs_s3_bucket_arn

  log_destination_type = var.flow_logs_destination

  tags = merge(local.common_tags, {
    Name = "${"${var.project}-${var.environment}"}-vpc-flow-logs"
  })
}
