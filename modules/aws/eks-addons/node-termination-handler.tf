# -----------------------------------------------------------------------------
# AWS Node Termination Handler (NTH)
# -----------------------------------------------------------------------------
# Gracefully drains nodes before SPOT reclamation, scheduled maintenance, and
# Auto Scaling lifecycle events. Runs in IMDS mode (no SQS queue required).
# Enable when any node group uses capacity_type = "SPOT".
# -----------------------------------------------------------------------------

resource "helm_release" "node_termination_handler" {
  count = var.enable_node_termination_handler ? 1 : 0

  name       = "aws-node-termination-handler"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-node-termination-handler"
  version    = var.node_termination_handler_version
  namespace  = "kube-system"

  atomic          = local.helm_release_defaults.atomic
  cleanup_on_fail = local.helm_release_defaults.cleanup_on_fail
  wait            = local.helm_release_defaults.wait
  timeout         = local.helm_release_defaults.timeout

  set {
    name  = "enableSpotInterruptionDraining"
    value = "true"
  }

  set {
    name  = "enableScheduledEventDraining"
    value = "true"
  }

  set {
    name  = "enableRebalanceMonitoring"
    value = "true"
  }

  set {
    name  = "enableRebalanceDraining"
    value = "false"
  }
}
