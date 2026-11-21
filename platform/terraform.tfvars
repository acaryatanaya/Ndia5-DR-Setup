############################################
# Cluster Autoscaler
############################################

cluster_autoscaler_chart_version = "9.54.0"
cluster_autoscaler_image_tag     = "v1.35.3"

############################################
# Additional Platform Tags
############################################

tags = {
  Owner = "DevOps"
  Layer = "EKS-Platform"
}

############################################
# AWS Load Balancer Controller
############################################

aws_load_balancer_controller_chart_version = "1.14.0"
aws_load_balancer_controller_image_tag     = "v2.14.1"


############################################
# External Secrets Operator
############################################

# Set this to the ESO chart version you have approved and tested.
external_secrets_chart_version = "2.15.0"

external_secrets_secret_names = [
  "ndia5/dr/backend",
  "ndia5/dr/transaction-scheduler",
  "ndia5/dr/report-scheduler"
]

# Null when using the AWS-managed Secrets Manager KMS key.
external_secrets_kms_key_arn = null
