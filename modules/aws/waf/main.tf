locals {
  name_prefix = "${var.project}-${var.environment}"

  default_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  tags = merge(local.default_tags, var.tags)
}

resource "aws_wafv2_web_acl" "this" {
  name  = "waf-${local.name_prefix}"
  scope = var.scope
  tags  = local.tags

  default_action {
    allow {}
  }

  dynamic "rule" {
    for_each = var.enable_rate_limiting ? [1] : []
    content {
      name     = "RateLimitPerIP"
      priority = 1

      action {
        block {}
      }

      statement {
        rate_based_statement {
          limit              = var.rate_limit_threshold
          aggregate_key_type = "IP"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "RateLimitPerIP"
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = var.enable_aws_managed_common_ruleset ? [1] : []
    content {
      name     = local.managed_rule_groups.common.name
      priority = local.managed_rule_groups.common.priority

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = local.managed_rule_groups.common.name
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = local.managed_rule_groups.common.name
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = var.enable_aws_managed_bad_inputs ? [1] : []
    content {
      name     = local.managed_rule_groups.bad_inputs.name
      priority = local.managed_rule_groups.bad_inputs.priority

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = local.managed_rule_groups.bad_inputs.name
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = local.managed_rule_groups.bad_inputs.name
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = var.enable_aws_managed_sql_injection ? [1] : []
    content {
      name     = local.managed_rule_groups.sql_injection.name
      priority = local.managed_rule_groups.sql_injection.priority

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = local.managed_rule_groups.sql_injection.name
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = local.managed_rule_groups.sql_injection.name
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = var.enable_aws_managed_ip_reputation ? [1] : []
    content {
      name     = local.managed_rule_groups.ip_reputation.name
      priority = local.managed_rule_groups.ip_reputation.priority

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = local.managed_rule_groups.ip_reputation.name
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = local.managed_rule_groups.ip_reputation.name
        sampled_requests_enabled   = true
      }
    }
  }

  dynamic "rule" {
    for_each = var.enable_per_uri_rate_limiting ? [1] : []
    content {
      name     = "RateLimitPerURI"
      priority = 2

      action {
        block {}
      }

      statement {
        rate_based_statement {
          limit              = var.per_uri_rate_limit_threshold
          aggregate_key_type = "IP"
        }

        and_statement {
          byte_match_statement {
            field_to_match {
              uri_path {}
            }
            string_match = var.per_uri_rate_limit_uri
            text_transformations {
              priority = 1
              type     = "NONE"
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "RateLimitPerURI"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "waf-${local.name_prefix}"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "alb" {
  for_each = toset(var.alb_arn_list)

  resource_arn = each.value
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}
