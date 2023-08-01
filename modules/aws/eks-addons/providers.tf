# -----------------------------------------------------------------------------
# Provider configuration for Helm and Kubernetes
# -----------------------------------------------------------------------------
# Uses the cluster endpoint and CA certificate passed in as variables so that
# callers do not need to configure these providers themselves.
# -----------------------------------------------------------------------------

provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name", var.cluster_name,
        "--region", var.region,
      ]
    }
  }
}
