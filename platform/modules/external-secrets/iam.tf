
############################################
# EKS Pod Identity Trust Policy
############################################

data "aws_iam_policy_document" "pod_identity_trust" {
  statement {
    sid     = "AllowEKSExternalSecretsPodIdentity"
    effect  = "Allow"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-namespace"
      values   = [var.namespace]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-service-account"
      values   = [var.service_account_name]
    }
  }
}

############################################
# ESO IAM Role
############################################

resource "aws_iam_role" "external_secrets" {
  name        = "${local.name}-role"
  description = "EKS Pod Identity role for External Secrets Operator"

  assume_role_policy = data.aws_iam_policy_document.pod_identity_trust.json

  tags = var.tags
}

############################################
# Secrets Manager Read Permissions
############################################

data "aws_iam_policy_document" "external_secrets" {
  statement {
    sid    = "ReadApprovedSecrets"
    effect = "Allow"

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue"
    ]

    resources = local.secret_arns
  }

  dynamic "statement" {
    for_each = var.kms_key_arn == null ? [] : [var.kms_key_arn]

    content {
      sid    = "DecryptSecretsManagerValues"
      effect = "Allow"

      actions = [
        "kms:Decrypt"
      ]

      resources = [statement.value]

      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["secretsmanager.${var.region}.amazonaws.com"]
      }
    }
  }
}

############################################
# ESO IAM Policy
############################################

resource "aws_iam_policy" "external_secrets" {
  name        = "${local.name}-policy"
  description = "Read-only access to approved Secrets Manager secrets"

  policy = data.aws_iam_policy_document.external_secrets.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  role       = aws_iam_role.external_secrets.name
  policy_arn = aws_iam_policy.external_secrets.arn
}

############################################
# EKS Pod Identity Association
############################################

resource "aws_eks_pod_identity_association" "external_secrets" {
  cluster_name    = var.cluster_name
  namespace       = var.namespace
  service_account = var.service_account_name
  role_arn        = aws_iam_role.external_secrets.arn

  depends_on = [
    aws_iam_role_policy_attachment.external_secrets
  ]
}
