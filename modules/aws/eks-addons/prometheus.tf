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

variable "prometheus_retention" {
  description = "Prometheus metrics retention period (e.g. 15d, 30d)"
  type        = string
  default     = "15d"
}

variable "prometheus_storage_size" {
  description = "PVC storage size for Prometheus data (e.g. 20Gi, 50Gi)"
  type        = string
  default     = "20Gi"
}

variable "enable_alertmanager" {
  description = "Enable Alertmanager as part of the Prometheus stack"
  type        = bool
  default     = true
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
    value = var.prometheus_retention
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.prometheus_storage_size
  }

  set {
    name  = "alertmanager.enabled"
    value = tostring(var.enable_alertmanager)
  }
}
