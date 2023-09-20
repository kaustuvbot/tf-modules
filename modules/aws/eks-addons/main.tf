# EKS Add-ons — install ordering and dependency graph
#
# Install sequence:
#   1. cert-manager          (provides CRDs used by ALB controller)
#   2. alb-controller        (depends on cert-manager for webhook)
#   3. external-dns          (depends on alb-controller for target group binding)
#   4. sealed-secrets        (independent, but after core controllers)
#   5. node-termination-handler (independent, manages SPOT lifecycle)
#   6. karpenter             (depends on IRSA role — created in karpenter.tf)
#   7. efs-csi-driver        (managed add-on, independent)
#   8. prometheus            (monitoring stack — after workload controllers)
#   9. grafana               (depends on prometheus for data source)
#  10. loki                  (independent log aggregation)
#
# depends_on relationships are declared in each resource file where needed.
# This file documents the intended ordering for maintainers.

# Helm provider is configured by the caller's root module.
# This module consumes the helm provider without declaring it.
