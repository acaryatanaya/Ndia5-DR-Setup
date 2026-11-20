
############################################
# Cluster Autoscaler Helm Deployment
############################################

resource "helm_release" "cluster_autoscaler" {

  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"

  version = var.helm_chart_version

  namespace        = local.namespace
  create_namespace = false

  ##########################################
  # Deployment Behaviour
  ##########################################

  wait            = true
  atomic          = true
  cleanup_on_fail = true
  timeout         = 600

  ##########################################
  # Helm Values
  ##########################################

  values = [
    yamlencode({

      ######################################
      # AWS Cloud Provider
      ######################################

      cloudProvider = "aws"

      awsRegion = var.region

      ######################################
      # ASG Auto Discovery
      ######################################

      autoDiscovery = {
        clusterName = var.cluster_name
      }

      ######################################
      # Cluster Autoscaler Image
      ######################################

      image = {
        repository = "registry.k8s.io/autoscaling/cluster-autoscaler"
        tag        = var.autoscaler_image_tag
        pullPolicy = "IfNotPresent"
      }

      ######################################
      # Kubernetes RBAC and IRSA
      ######################################

      rbac = {
        create = true

        serviceAccount = {
          create = true
          name   = local.service_account

          automountServiceAccountToken = true

          annotations = {
            "eks.amazonaws.com/role-arn" = aws_iam_role.cluster_autoscaler.arn
          }
        }
      }

      ######################################
      # Replica Configuration
      ######################################

      replicaCount = 1

      ######################################
      # Autoscaler Arguments
      ######################################

      extraArgs = {
        "expander" = "least-waste"
        "v"        = 4
      }

      ######################################
      # Resource Requests and Limits
      ######################################

      resources = {
        requests = {
          cpu    = "100m"
          memory = "300Mi"
        }

        limits = {
          cpu    = "500m"
          memory = "600Mi"
        }
      }
    })
  ]

  ##########################################
  # IAM Dependency
  ##########################################

  depends_on = [
    aws_iam_role_policy_attachment.cluster_autoscaler
  ]
}
