############################################
# AWS Load Balancer Controller Locals
############################################

locals {
  name            = "${var.cluster_name}-aws-load-balancer-controller"
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"

  # Normalize the OIDC issuer for IAM condition keys.
  oidc_issuer = trimsuffix(
    trimprefix(var.oidc_issuer, "https://"),
    "/"
  )

  tags = merge(
    var.tags,
    {
      Component = "AWSLoadBalancerController"
    }
  )
}
