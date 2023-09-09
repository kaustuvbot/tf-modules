# -----------------------------------------------------------------------------
# ExternalDNS
# -----------------------------------------------------------------------------
# Automatically manages Route53 DNS records for Kubernetes services
# and ingresses.
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "external_dns_assume" {
  count = var.enable_external_dns ? 1 : 0

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
      values   = ["system:serviceaccount:kube-system:external-dns"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["route53:ChangeResourceRecordSets"]
    resources = [for id in var.route53_zone_ids : "arn:aws:route53:::hostedzone/${id}"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  name               = "${var.project}-${var.environment}-external-dns"
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume[0].json

  tags = merge(var.tags, {
    Name   = "${var.project}-${var.environment}-external-dns"
    AddOn  = "external-dns"
    Module = "eks-addons"
  })
}

resource "aws_iam_role_policy" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  name   = "external-dns-route53"
  role   = aws_iam_role.external_dns[0].id
  policy = data.aws_iam_policy_document.external_dns[0].json
}

resource "helm_release" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  name       = "external-dns"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  version    = var.external_dns_version

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "aws.region"
    value = data.aws_region.current.name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.external_dns[0].arn
  }

  set {
    name  = "policy"
    value = "sync"
  }

  set {
    name  = "txtOwnerId"
    value = "${var.project}-${var.environment}"
  }

  timeout         = local.helm_release_defaults.timeout
  atomic          = local.helm_release_defaults.atomic
  cleanup_on_fail = local.helm_release_defaults.cleanup_on_fail
  wait            = local.helm_release_defaults.wait
}
