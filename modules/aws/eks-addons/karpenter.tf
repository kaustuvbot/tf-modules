# -----------------------------------------------------------------------------
# Karpenter Node Autoscaler
# -----------------------------------------------------------------------------
# Creates:
#   - SQS queue for SPOT interruption and health event notifications
#   - EventBridge rules routing EC2 lifecycle events to the queue
#   - IRSA IAM role with EC2/SQS/SSM/EKS permissions for the controller
#   - Karpenter Helm release
#
# After applying, create NodePool and EC2NodeClass resources to define
# node provisioning policies. See docs/karpenter-migration.md.
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {
  count = var.enable_karpenter ? 1 : 0
}

# -----------------------------------------------------------------------------
# SQS Interruption Queue
# -----------------------------------------------------------------------------

resource "aws_sqs_queue" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  name                      = "${var.cluster_name}-karpenter"
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-karpenter"
  })
}

resource "aws_sqs_queue_policy" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  queue_url = aws_sqs_queue.karpenter[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridge"
        Effect = "Allow"
        Principal = {
          Service = ["events.amazonaws.com", "sqs.amazonaws.com"]
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.karpenter[0].arn
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# EventBridge Rules → SQS
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "karpenter_spot_interruption" {
  count = var.enable_karpenter ? 1 : 0

  name        = "${var.cluster_name}-karpenter-spot"
  description = "Karpenter: EC2 Spot Instance interruption warnings"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "karpenter_spot_interruption" {
  count = var.enable_karpenter ? 1 : 0

  rule = aws_cloudwatch_event_rule.karpenter_spot_interruption[0].name
  arn  = aws_sqs_queue.karpenter[0].arn
}

resource "aws_cloudwatch_event_rule" "karpenter_health" {
  count = var.enable_karpenter ? 1 : 0

  name        = "${var.cluster_name}-karpenter-health"
  description = "Karpenter: AWS Health scheduled change notifications"

  event_pattern = jsonencode({
    source      = ["aws.health"]
    detail-type = ["AWS Health Event"]
  })

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "karpenter_health" {
  count = var.enable_karpenter ? 1 : 0

  rule = aws_cloudwatch_event_rule.karpenter_health[0].name
  arn  = aws_sqs_queue.karpenter[0].arn
}

# -----------------------------------------------------------------------------
# IRSA Role for Karpenter Controller
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "karpenter_assume" {
  count = var.enable_karpenter ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.karpenter_namespace}:karpenter"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  name               = "${var.cluster_name}-karpenter"
  assume_role_policy = data.aws_iam_policy_document.karpenter_assume[0].json

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-karpenter"
  })
}

resource "aws_iam_role_policy" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  name = "karpenter"
  role = aws_iam_role.karpenter[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2NodeManagement"
        Effect = "Allow"
        Action = [
          "ec2:CreateFleet",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateTags",
          "ec2:DeleteLaunchTemplate",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeSubnets",
          "ec2:RunInstances",
          "ec2:TerminateInstances",
        ]
        Resource = "*"
      },
      {
        Sid      = "PassNodeRole"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ec2.amazonaws.com"
          }
        }
      },
      {
        Sid    = "SQSInterruption"
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage",
        ]
        Resource = aws_sqs_queue.karpenter[0].arn
      },
      {
        Sid      = "SSMParameter"
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = "arn:aws:ssm:*:*:parameter/aws/service/eks/optimized-ami/*"
      },
      {
        Sid      = "EKSCluster"
        Effect   = "Allow"
        Action   = ["eks:DescribeCluster"]
        Resource = "*"
      },
    ]
  })
}

# -----------------------------------------------------------------------------
# Karpenter Helm Release
# -----------------------------------------------------------------------------

resource "helm_release" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_version
  namespace  = var.karpenter_namespace

  create_namespace = true
  atomic           = local.helm_release_defaults.atomic
  cleanup_on_fail  = local.helm_release_defaults.cleanup_on_fail
  wait             = local.helm_release_defaults.wait
  timeout          = local.helm_release_defaults.timeout

  set {
    name  = "settings.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "settings.interruptionQueue"
    value = aws_sqs_queue.karpenter[0].name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter[0].arn
  }

  depends_on = [
    aws_iam_role_policy.karpenter,
    aws_sqs_queue_policy.karpenter,
  ]
}
