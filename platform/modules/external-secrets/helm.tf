
############################################
# External Secrets Operator Helm Release
############################################

resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = var.helm_chart_version

  namespace        = var.namespace
  create_namespace = true

  wait            = true
  atomic          = true
  cleanup_on_fail = true
  timeout         = 600

  values = [
    yamlencode({
      installCRDs = true

      replicaCount = 1

      serviceAccount = {
        create = true
        name   = var.service_account_name
      }

      resources = {
        requests = {
          cpu    = "100m"
          memory = "128Mi"
        }

        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }
    })
  ]

  depends_on = [
    aws_eks_pod_identity_association.external_secrets,
    aws_iam_role_policy_attachment.external_secrets
  ]
}
