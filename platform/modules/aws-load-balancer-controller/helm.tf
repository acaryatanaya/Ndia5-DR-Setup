############################################
# Controller Kubernetes Service Account
############################################

resource "kubernetes_service_account_v1" "aws_load_balancer_controller" {
  metadata {
    name      = local.service_account
    namespace = local.namespace

    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_load_balancer_controller.arn
    }
  }

  automount_service_account_token = true

  depends_on = [
    aws_iam_role_policy_attachment.aws_load_balancer_controller
  ]
}

############################################
# AWS Load Balancer Controller Helm Release
############################################

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.helm_chart_version

  namespace        = local.namespace
  create_namespace = false

  wait            = true
  atomic          = true
  cleanup_on_fail = true
  timeout         = 900

  values = [
    yamlencode({
      clusterName = var.cluster_name
      region      = var.region
      vpcId       = var.vpc_id

      image = {
        repository = "public.ecr.aws/eks/aws-load-balancer-controller"
        tag        = var.controller_image_tag
        pullPolicy = "IfNotPresent"
      }

      replicaCount = 2

      serviceAccount = {
        create = false
        name   = kubernetes_service_account_v1.aws_load_balancer_controller.metadata[0].name
      }

      # Keep the chart's default webhook and service mutator settings.
      # The controller uses the existing IRSA service account above.
    })
  ]

  depends_on = [
    kubernetes_service_account_v1.aws_load_balancer_controller,
    aws_iam_role_policy_attachment.aws_load_balancer_controller
  ]
}
