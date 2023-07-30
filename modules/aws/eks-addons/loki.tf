# -----------------------------------------------------------------------------
# Loki (log aggregation)
# -----------------------------------------------------------------------------

variable "enable_loki" {
  description = "Whether to install Loki for log aggregation"
  type        = bool
  default     = false
}

variable "loki_version" {
  description = "Helm chart version for loki-stack"
  type        = string
  default     = "2.10.2"
}

variable "loki_namespace" {
  description = "Kubernetes namespace for Loki"
  type        = string
  default     = "monitoring"
}

resource "helm_release" "loki" {
  count = var.enable_loki ? 1 : 0

  name             = "loki-stack"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki-stack"
  version          = var.loki_version
  namespace        = var.loki_namespace
  create_namespace = true
  atomic           = true
  timeout          = 300

  set {
    name  = "loki.persistence.enabled"
    value = "true"
  }

  set {
    name  = "loki.persistence.size"
    value = "10Gi"
  }

  # Disable Grafana in loki-stack; use the one from kube-prometheus-stack
  set {
    name  = "grafana.enabled"
    value = "false"
  }

  set {
    name  = "promtail.enabled"
    value = "true"
  }

  depends_on = [helm_release.prometheus]
}
