# -----------------------------------------------------------------------------
# AWS IAM Module
# -----------------------------------------------------------------------------
# Manages GitHub OIDC federation and CI/CD roles for Terraform automation.
#
# Resources created:
#   - GitHub OIDC identity provider
#   - CI plan role (read-only)
#   - CI apply role (read-write)
# -----------------------------------------------------------------------------

locals {
  github_oidc_url = "https://token.actions.githubusercontent.com"

  # Build sub claims for each repo: "repo:org/repo:*"
  oidc_sub_claims = [
    for repo in var.github_repositories : "repo:${repo}:*"
  ]

  common_tags = merge(
    {
      Module      = "iam"
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}

# -----------------------------------------------------------------------------
# GitHub OIDC Identity Provider
# -----------------------------------------------------------------------------

data "tls_certificate" "github" {
  url = local.github_oidc_url
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = local.github_oidc_url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  tags = merge(local.common_tags, {
    Name = "${var.project}-github-oidc"
  })
}

# -----------------------------------------------------------------------------
# CI Plan Role (read-only)
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "plan_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.oidc_sub_claims
    }
  }
}

resource "aws_iam_role" "plan" {
  name               = "${var.project}-${var.environment}-ci-plan"
  assume_role_policy = data.aws_iam_policy_document.plan_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-ci-plan"
    Role = "ci-plan"
  })
}

resource "aws_iam_role_policy_attachment" "plan_read_only" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# -----------------------------------------------------------------------------
# CI Apply Role (read-write)
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "apply_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.oidc_sub_claims
    }
  }
}

resource "aws_iam_role" "apply" {
  name               = "${var.project}-${var.environment}-ci-apply"
  assume_role_policy = data.aws_iam_policy_document.apply_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-ci-apply"
    Role = "ci-apply"
  })
}

resource "aws_iam_role_policy_attachment" "apply_power_user" {
  role       = aws_iam_role.apply.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}
