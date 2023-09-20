# -----------------------------------------------------------------------------
# Grafana — dashboards and visualization
# Installed when enable_grafana = true
# Requires enable_prometheus = true for data sources
# -----------------------------------------------------------------------------

variable "enable_grafana" {
  description = "Install Grafana dashboards. Requires enable_prometheus=true for the Prometheus data source."
  type        = bool
  default     = false
}

variable "grafana_version" {
  description = "Helm chart version for Grafana"
  type        = string
  default     = "7.3.3"
}

variable "grafana_persistence_enabled" {
  description = "Enable persistent storage for Grafana dashboards and configuration"
  type        = bool
  default     = true
}

variable "grafana_storage_size" {
  description = "PVC storage size for Grafana persistence"
  type        = string
  default     = "10Gi"
}

resource "helm_release" "grafana" {
  count = var.enable_grafana ? 1 : 0

  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  version          = var.grafana_version
  namespace        = "monitoring"
  create_namespace = true
  atomic           = true
  timeout          = 300

  set {
    name  = "persistence.enabled"
    value = tostring(var.grafana_persistence_enabled)
  }

  set {
    name  = "persistence.size"
    value = var.grafana_storage_size
  }

  set {
    name  = "datasources.datasources\\.yaml.apiVersion"
    value = "1"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].name"
    value = "Prometheus"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].type"
    value = "prometheus"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].url"
    value = "http://kube-prometheus-stack-prometheus.monitoring.svc:9090"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].isDefault"
    value = "true"
  }
}
