
############################################
# Cluster Autoscaler IRSA Trust Policy
############################################

data "aws_iam_policy_document" "assume_role" {

  statement {
    sid     = "AllowClusterAutoscalerServiceAccount"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    # Restrict the role to the exact service account.
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:sub"

      values = [
        "system:serviceaccount:${local.namespace}:${local.service_account}"
      ]
    }

    # Restrict token audience.
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:aud"

      values = [
        "sts.amazonaws.com"
      ]
    }
  }
}

############################################
# Cluster Autoscaler IAM Role
############################################

resource "aws_iam_role" "cluster_autoscaler" {

  name = local.name

  description = "IRSA role for EKS Cluster Autoscaler on ${var.cluster_name}"

  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = local.tags
}

############################################
# Cluster Autoscaler IAM Permissions
############################################

data "aws_iam_policy_document" "cluster_autoscaler" {

  ##########################################
  # Read Permissions
  ##########################################

  statement {
    sid    = "ClusterAutoscalerReadPermissions"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",

      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:GetInstanceTypesFromInstanceRequirements",

      "eks:DescribeNodegroup"
    ]

    resources = ["*"]
  }

  ##########################################
  # Restricted Scaling Permissions
  ##########################################

  statement {
    sid    = "ClusterAutoscalerScalingPermissions"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/k8s.io/cluster-autoscaler/enabled"

      values = ["true"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/k8s.io/cluster-autoscaler/${var.cluster_name}"

      values = ["owned"]
    }
  }
}

############################################
# IAM Policy
############################################

resource "aws_iam_policy" "cluster_autoscaler" {

  name = "${local.name}-policy"

  description = "Least privilege IAM permissions for Cluster Autoscaler"

  policy = data.aws_iam_policy_document.cluster_autoscaler.json

  tags = local.tags
}

############################################
# IAM Policy Attachment
############################################

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {

  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}
