output "vpc_id" {
  description = "ID of the VPC. Pass to eks.vpc_id, security groups, and other resources that need vpc_id."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs, one per AZ. Use for load balancers, NAT gateways, and bastion hosts."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs, one per AZ. Pass to eks.subnet_ids for node group placement."
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = length(aws_internet_gateway.this) > 0 ? aws_internet_gateway.this[0].id : null
}

output "nat_gateway_ids" {
  description = "List of NAT gateway IDs"
  value       = aws_nat_gateway.this[*].id
}

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = length(aws_route_table.public) > 0 ? aws_route_table.public[0].id : null
}

output "private_route_table_ids" {
  description = "List of private route table IDs. Length is 1 when single_nat_gateway=true, otherwise equals the AZ count."
  value       = aws_route_table.private[*].id
}

output "flow_log_id" {
  description = "ID of the VPC flow log resource, or null if flow logs are disabled"
  value       = length(aws_flow_log.this) > 0 ? aws_flow_log.this[0].id : null
}

output "flow_log_cloudwatch_log_group_name" {
  description = "CloudWatch log group name used for flow logs, or null if not applicable"
  value       = var.enable_flow_logs && var.flow_logs_destination == "cloud-watch-logs" ? var.flow_logs_cloudwatch_log_group_name : null
}

output "ssm_vpc_endpoint_ids" {
  description = "Map of SSM VPC endpoint IDs (ssm, ssmmessages, ec2messages). Empty map when enable_ssm_vpc_endpoints=false."
  value = var.enable_ssm_vpc_endpoints ? {
    ssm         = aws_vpc_endpoint.ssm[0].id
    ssmmessages = aws_vpc_endpoint.ssmmessages[0].id
    ec2messages = aws_vpc_endpoint.ec2messages[0].id
  } : {}
}
