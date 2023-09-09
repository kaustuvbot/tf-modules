# -----------------------------------------------------------------------------
# cert-manager
# -----------------------------------------------------------------------------
# Automates TLS certificate issuance and renewal for Kubernetes
# workloads. Supports Route53 DNS01 challenge solver via IRSA.
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "cert_manager_assume" {
  count = var.enable_cert_manager ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:cert-manager:cert-manager"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["route53:GetChange"]
    resources = ["arn:aws:route53:::change/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
    ]
    resources = [for id in var.route53_zone_ids : "arn:aws:route53:::hostedzone/${id}"]
  }

  statement {
    effect    = "Allow"
    actions   = ["route53:ListHostedZonesByName"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  name               = "${var.project}-${var.environment}-cert-manager"
  assume_role_policy = data.aws_iam_policy_document.cert_manager_assume[0].json

  tags = merge(var.tags, {
    Name   = "${var.project}-${var.environment}-cert-manager"
    AddOn  = "cert-manager"
    Module = "eks-addons"
  })
}

resource "aws_iam_role_policy" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  name   = "cert-manager-route53"
  role   = aws_iam_role.cert_manager[0].id
  policy = data.aws_iam_policy_document.cert_manager[0].json
}

resource "helm_release" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_version

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "cert-manager"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.cert_manager[0].arn
  }

  set {
    name  = "securityContext.fsGroup"
    value = "1001"
  }

  timeout         = 600
  atomic          = true
  cleanup_on_fail = true
  wait            = true
  wait_for_jobs   = true

  # CRDs must be installed before ExternalDNS or ALB controller
  # can reference cert-manager annotations
  depends_on = [
    helm_release.alb_controller,
  ]
}
