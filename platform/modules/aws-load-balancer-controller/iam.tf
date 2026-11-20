############################################
# AWS Load Balancer Controller IRSA Trust Policy
############################################

data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "AllowAWSLoadBalancerControllerServiceAccount"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:sub"
      values   = ["system:serviceaccount:${local.namespace}:${local.service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

############################################
# IAM Role
############################################

resource "aws_iam_role" "aws_load_balancer_controller" {
  name        = local.name
  description = "IRSA role for AWS Load Balancer Controller on ${var.cluster_name}"

  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

############################################
# AWS-Published Controller IAM Policy
############################################

resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "${local.name}-policy"
  description = "AWS Load Balancer Controller permissions for ${var.cluster_name}"

  policy = file("${path.module}/iam_policy.json")
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}
