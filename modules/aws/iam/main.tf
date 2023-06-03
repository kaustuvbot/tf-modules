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
