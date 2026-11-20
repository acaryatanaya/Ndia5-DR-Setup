############################################
# Cluster Autoscaler
############################################

cluster_autoscaler_chart_version = "9.51.0"
cluster_autoscaler_image_tag     = "v1.34.6"

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