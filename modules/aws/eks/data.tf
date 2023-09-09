# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------
# Centralised here to make external dependencies explicit and easy to find.
# -----------------------------------------------------------------------------

# TLS certificate for the EKS OIDC issuer endpoint.
# The SHA-1 thumbprint is required to register the OIDC provider.
# Must reference the cluster resource so it is fetched after cluster creation.
data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# Current AWS account and region — used in ARN composition and naming.
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
