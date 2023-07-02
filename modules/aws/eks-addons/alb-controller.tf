# -----------------------------------------------------------------------------
# AWS Load Balancer Controller
# -----------------------------------------------------------------------------
# Manages ALB/NLB ingress for EKS workloads.
# Requires IRSA role with appropriate IAM permissions.
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "alb_controller_assume" {
  count = var.enable_alb_controller ? 1 : 0

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
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "alb_controller" {
  count = var.enable_alb_controller ? 1 : 0

  name               = "${var.project}-${var.environment}-alb-controller"
  assume_role_policy = data.aws_iam_policy_document.alb_controller_assume[0].json

  tags = merge(var.tags, {
    Name    = "${var.project}-${var.environment}-alb-controller"
    AddOn   = "aws-load-balancer-controller"
    Module  = "eks-addons"
  })
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  count = var.enable_alb_controller ? 1 : 0

  role       = aws_iam_role.alb_controller[0].name
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}

resource "helm_release" "alb_controller" {
  count = var.enable_alb_controller ? 1 : 0

  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.alb_controller_version

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.alb_controller[0].arn
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "region"
    value = data.aws_region.current.name
  }

  timeout          = 300
  atomic           = true
  cleanup_on_fail  = true
  wait             = true
  wait_for_jobs    = true
}
