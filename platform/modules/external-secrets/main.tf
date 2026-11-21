
############################################
# Existing AWS Secrets Manager Secrets
############################################

data "aws_secretsmanager_secret" "existing" {
  for_each = var.secret_names

  name = each.value
}

############################################
# Local Values
############################################

locals {
  name = "${var.cluster_name}-eso"

  secret_arns = [
    for secret in data.aws_secretsmanager_secret.existing :
    secret.arn
  ]
}
