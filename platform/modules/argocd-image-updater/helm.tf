
resource "helm_release" "image_updater" {
  name       = "argocd-image-updater"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-image-updater"
  version    = var.helm_chart_version

  namespace        = var.namespace
  create_namespace = false

  wait            = true
  atomic          = true
  cleanup_on_fail = true
  timeout         = 600

  values = [
    yamlencode({
      replicaCount = 1

      serviceAccount = {
        create = true
        name   = var.service_account_name
      }

      rbac = {
        enabled = true
      }

      createClusterRoles = true

      config = {
        "log.level" = "info"

        registries = [
          {
            name        = "Hyderabad ECR"
            api_url     = "https://${var.account_id}.dkr.ecr.${var.region}.amazonaws.com"
            prefix      = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com"
            ping        = true
            insecure    = false
            credentials = "ext:/scripts/ecr-login.sh"
            credsexpire = "10h"
          }
        ]
      }

      authScripts = {
        enabled = true

        scripts = {
          "ecr-login.sh" = <<-SCRIPT
            #!/bin/sh
            set -eu

            PASSWORD=$(/opt/aws-cli/usr/bin/aws ecr get-login-password \
              --region "${var.region}")

            printf 'AWS:%s\n' "$PASSWORD"
          SCRIPT
        }
      }

      extraEnv = [
        {
          name  = "AWS_REGION"
          value = var.region
        },
        {
          name  = "AWS_DEFAULT_REGION"
          value = var.region
        },
        {
          name  = "AWS_PAGER"
          value = ""
        },
        {
          name  = "PYTHONHOME"
          value = "/opt/aws-cli/usr"
        },
        {
          name  = "PYTHONPATH"
          value = "/opt/aws-cli/usr/lib/python3.14/site-packages"
        },
        {
          name  = "LD_LIBRARY_PATH"
          value = "/opt/aws-cli/usr/lib:/opt/aws-cli/lib"
        }
      ]

      initContainers = [
        {
          name    = "install-aws-cli"
          image   = "quay.io/argoprojlabs/argocd-image-updater:v1.3.1"
          command = ["/bin/sh", "-c"]

          args = [
            <<-SCRIPT
              set -eu

              apk --root /opt/aws-cli \
                --initdb \
                --repositories-file /etc/apk/repositories \
                --keys-dir /etc/apk/keys \
                add aws-cli

              test -x /opt/aws-cli/usr/bin/aws
              test -x /opt/aws-cli/usr/bin/python3

              echo "AWS CLI installation completed successfully"
            SCRIPT
          ]

          securityContext = {
            runAsUser                = 0
            runAsGroup               = 0
            runAsNonRoot             = false
            allowPrivilegeEscalation = false
          }

          volumeMounts = [
            {
              name      = "aws-cli-tools"
              mountPath = "/opt/aws-cli"
            }
          ]
        }
      ]

      volumes = [
        {
          name     = "aws-cli-tools"
          emptyDir = {}
        }
      ]

      volumeMounts = [
        {
          name      = "aws-cli-tools"
          mountPath = "/opt/aws-cli"
          readOnly  = true
        }
      ]

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
    aws_eks_pod_identity_association.image_updater
  ]
}
