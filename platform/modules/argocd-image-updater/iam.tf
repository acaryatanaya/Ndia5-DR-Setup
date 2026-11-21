data "aws_iam_policy_document" "pod_identity_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        "arn:aws:eks:${var.region}:${var.account_id}:cluster/${var.cluster_name}"
      ]
    }
  }
}

resource "aws_iam_role" "image_updater" {
  name               = "${var.cluster_name}-image-updater-role"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-image-updater-role"
  })
}

data "aws_iam_policy_document" "ecr_read" {
  statement {
    sid    = "ECRAuthorization"
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ECRRepositoryRead"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:ListImages"
    ]

    resources = local.ecr_repository_arns
  }
}

resource "aws_iam_role_policy" "ecr_read" {
  name   = "${var.cluster_name}-image-updater-ecr-read"
  role   = aws_iam_role.image_updater.id
  policy = data.aws_iam_policy_document.ecr_read.json
}

resource "aws_eks_pod_identity_association" "image_updater" {
  cluster_name    = var.cluster_name
  namespace       = var.namespace
  service_account = var.service_account_name
  role_arn        = aws_iam_role.image_updater.arn

  depends_on = [
    aws_iam_role_policy.ecr_read
  ]
}