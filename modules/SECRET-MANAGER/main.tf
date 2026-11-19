############################################
# 1. Create AWS Secrets Manager secrets
############################################

resource "aws_secretsmanager_secret" "this" {
  for_each = var.secret_definitions

  name        = each.key
  description = each.value

  # Null means AWS-managed Secrets Manager encryption key.
  kms_key_id = var.kms_key_arn

  # Keep deleted secrets recoverable for 30 days.
  recovery_window_in_days = 30

  tags = var.tags
}

############################################
# Define actual secret values
############################################

locals {
  secret_values = {
    "ndia5/dr/database" = jsonencode({
      host     = "your-rds-endpoint"
      port     = "5432"
      dbname   = "ndia5"
      username = "your-database-username"
      password = "your-database-password"
    })
  }
}

############################################
# Store values in AWS Secrets Manager
############################################

resource "aws_secretsmanager_secret_version" "this" {
  for_each = local.secret_values

  secret_id = aws_secretsmanager_secret.this[each.key].id

  secret_string_wo = each.value

  secret_string_wo_version = 1
}

############################################
# 2. Pod Identity IAM trust policy
############################################

data "aws_iam_policy_document" "pod_identity_trust" {
  statement {
    sid    = "AllowEKSPodIdentity"
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]

    principals {
      type = "Service"

      identifiers = [
        "pods.eks.amazonaws.com"
      ]
    }

    # Restrict access to the intended EKS cluster.
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/eks-cluster-arn"
      values   = [var.cluster_arn]
    }

    # Restrict access to the ESO namespace.
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-namespace"
      values   = [var.namespace]
    }

    # Restrict access to the ESO service account.
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-service-account"
      values   = [var.service_account]
    }
  }
}


############################################
# 3. Create IAM role for ESO
############################################

resource "aws_iam_role" "external_secrets" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.pod_identity_trust.json

  tags = merge(var.tags, {
    Name = var.role_name
  })
}


############################################
# 4. Secrets Manager read permissions
############################################

data "aws_iam_policy_document" "secrets_read" {

  statement {
    sid    = "ReadNDIA5DRSecrets"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:ListSecretVersionIds"
    ]

    # Grant access only to secrets created by this module.
    resources = [
      for secret in values(aws_secretsmanager_secret.this) :
      secret.arn
    ]
  }

  # Additional permission only when a customer-managed
  # KMS key is configured for Secrets Manager.
  dynamic "statement" {
    for_each = var.kms_key_arn == null ? [] : [var.kms_key_arn]

    content {
      sid       = "DecryptSecretsManagerKey"
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
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
# 5. Create customer-managed IAM policy
############################################

resource "aws_iam_policy" "external_secrets" {
  name        = "${var.role_name}-policy"
  description = "Read approved NDIA5 DR secrets for External Secrets Operator"

  policy = data.aws_iam_policy_document.secrets_read.json

  tags = var.tags
}


############################################
# 6. Attach policy to ESO IAM role
############################################

resource "aws_iam_role_policy_attachment" "external_secrets" {
  role       = aws_iam_role.external_secrets.name
  policy_arn = aws_iam_policy.external_secrets.arn
}


############################################
# 7. EKS Pod Identity association
############################################

resource "aws_eks_pod_identity_association" "external_secrets" {

  cluster_name    = var.cluster_name
  namespace       = var.namespace
  service_account = var.service_account

  role_arn = aws_iam_role.external_secrets.arn

  depends_on = [
    aws_iam_role_policy_attachment.external_secrets
  ]
}