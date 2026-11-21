locals {
  name = "argocd-image-updater"

  ecr_repository_arns = [
    for repository in var.ecr_repository_names :
    "arn:aws:ecr:${var.region}:${var.account_id}:repository/${repository}"
  ]
}