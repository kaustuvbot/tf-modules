# -----------------------------------------------------------------------------
# kube-prometheus-stack (Prometheus + Alertmanager + Grafana)
# -----------------------------------------------------------------------------

variable "enable_prometheus" {
  description = "Whether to install kube-prometheus-stack"
  type        = bool
  default     = false
}

variable "prometheus_version" {
  description = "Helm chart version for kube-prometheus-stack"
  type        = string
  default     = "55.5.0"
}

variable "prometheus_namespace" {
  description = "Kubernetes namespace for the Prometheus stack"
  type        = string
  default     = "monitoring"
}

variable "grafana_admin_password" {
  description = "Grafana admin password. If null, a random password is generated."
  type        = string
  default     = null
  sensitive   = true
}

resource "helm_release" "prometheus" {
  count = var.enable_prometheus ? 1 : 0

  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = var.prometheus_version
  namespace        = var.prometheus_namespace
  create_namespace = true
  atomic           = true
  timeout          = 600

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password != null ? var.grafana_admin_password : "changeme"
  }

  set {
    name  = "prometheus.prometheusSpec.retention"
    value = "15d"
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = "20Gi"
  }
}
