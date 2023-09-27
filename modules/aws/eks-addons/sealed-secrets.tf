# -----------------------------------------------------------------------------
# Bitnami Sealed Secrets Controller
# -----------------------------------------------------------------------------
# Enables GitOps-safe secret management: secrets are encrypted with the
# controller's asymmetric key and the resulting SealedSecret is safe to commit
# to version control. Only the controller running in the cluster can decrypt.
# No IRSA role is required — the controller does not make AWS API calls.
# -----------------------------------------------------------------------------

resource "helm_release" "sealed_secrets" {
  count = var.enable_sealed_secrets ? 1 : 0

  name       = "sealed-secrets"
  repository = "https://bitnami-labs.github.io/sealed-secrets"
  chart      = "sealed-secrets"
  version    = var.sealed_secrets_version
  namespace  = "kube-system"

  atomic          = local.helm_release_defaults.atomic
  cleanup_on_fail = local.helm_release_defaults.cleanup_on_fail
  wait            = local.helm_release_defaults.wait
  timeout         = local.helm_release_defaults.timeout

  set {
    name  = "fullnameOverride"
    value = "sealed-secrets-controller"
  }
}
