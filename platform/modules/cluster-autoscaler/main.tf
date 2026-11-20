
############################################
# Cluster Autoscaler Locals
############################################

locals {
  name = "${var.cluster_name}-cluster-autoscaler"

  namespace       = "kube-system"
  service_account = "cluster-autoscaler"

  # Infrastructure provides the issuer without https://.
  oidc_issuer = trimsuffix(
    trimprefix(var.oidc_issuer, "https://"),
    "/"
  )

  tags = merge(
    var.tags,
    {
      Component = "ClusterAutoscaler"
    }
  )
}
