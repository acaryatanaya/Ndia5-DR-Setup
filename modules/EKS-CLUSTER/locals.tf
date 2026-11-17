locals {
  # ---- Secrets encryption key ----
  create_kms = var.create_kms_key && var.kms_key_arn == null
  kms_arn    = local.create_kms ? aws_kms_key.this[0].arn : var.kms_key_arn

  # ---- Worker nodes ----
  # eks-node-1, eks-node-2, ... -> index (1-based)
  nodes = { for i in range(1, var.node_count + 1) : "${var.node_name_prefix}-${i}" => i }

  node_policy_arns = toset(concat([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ], var.node_additional_policy_arns))

  # The EKS-created cluster security group first (nodes must reach the control plane), then yours.
  node_security_group_ids = concat(
    [aws_eks_cluster.this.vpc_config[0].cluster_security_group_id],
    var.node_security_group_ids
  )

  # ---- Add-ons: IRSA roles for the ones that need AWS API access ----
  irsa_definitions = {
    "vpc-cni" = {
      namespace       = "kube-system"
      service_account = "aws-node"
      policy_arn      = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    }
    "aws-ebs-csi-driver" = {
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
      policy_arn      = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    }
  }

  # Only build roles for add-ons that were actually requested.
  irsa_roles = {
    for k, v in local.irsa_definitions : k => v if contains(keys(var.addons), k)
  }

  oidc_provider_url_bare = replace(aws_iam_openid_connect_provider.this.url, "https://", "")
}
