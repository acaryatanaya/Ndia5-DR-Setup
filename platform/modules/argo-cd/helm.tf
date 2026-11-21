
resource "helm_release" "argocd" {
  name       = local.release_name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.helm_chart_version

  namespace        = var.namespace
  create_namespace = true

  wait            = true
  atomic          = true
  cleanup_on_fail = true
  timeout         = 900

  values = [
    yamlencode({
      crds = {
        install = true
        keep    = true
      }

      global = {
        domain = var.server_hostname
      }
      
      server = {
        replicas = 2

        service = {
          type = "ClusterIP"
        }

        ingress = {
          enabled = false
        }
      }

      configs = {
        params = {
          "server.insecure" = true
        }
      }

      controller = {
        replicas = 1
      }

      repoServer = {
        replicas = 2
      }

      applicationSet = {
        replicas = 1
      }

      redis = {
        enabled = true
      }
    })
  ]
}
