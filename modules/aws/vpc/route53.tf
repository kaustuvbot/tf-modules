# Route53 health check for DNS failover routing.
# Enable with enable_route53_health_check = true.

resource "aws_route53_health_check" "this" {
  count = var.enable_route53_health_check ? 1 : 0

  fqdn              = var.route53_health_check_fqdn
  port              = var.route53_health_check_port
  type              = var.route53_health_check_type
  failure_threshold = 3
  request_interval  = 30

  tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Name        = "hc-${var.project}-${var.environment}"
    },
    var.tags
  )
}
