############################
# IAM role for the control plane
############################
data "aws_iam_policy_document" "assume_eks" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name_prefix        = "${var.name}-cluster-role-"
  assume_role_policy = data.aws_iam_policy_document.assume_eks.json

  tags = merge(var.tags, { Name = "${var.name}-cluster-role" })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

############################
# KMS key for Kubernetes secrets encryption
############################
resource "aws_kms_key" "this" {
  count = local.create_kms ? 1 : 0

  description             = "EKS secrets encryption for ${var.name}"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  tags = merge(var.tags, { Name = "${var.name}-eks-secrets" })
}

resource "aws_kms_alias" "this" {
  count = local.create_kms ? 1 : 0

  name          = "alias/${var.name}-eks-secrets"
  target_key_id = aws_kms_key.this[0].key_id
}

data "aws_iam_policy_document" "cluster_kms" {
  count = local.kms_arn != null ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ListGrants",
      "kms:DescribeKey",
      "kms:CreateGrant",
    ]
    resources = [local.kms_arn]
  }
}

resource "aws_iam_role_policy" "cluster_kms" {
  count = local.kms_arn != null ? 1 : 0

  name   = "${var.name}-cluster-kms"
  role   = aws_iam_role.cluster.id
  policy = data.aws_iam_policy_document.cluster_kms[0].json
}

############################
# Control plane logs
############################
resource "aws_cloudwatch_log_group" "this" {
  count = length(var.enabled_log_types) > 0 ? 1 : 0

  name              = "/aws/eks/${var.name}/cluster"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

############################
# Security groups
#   cluster: extra group on the control-plane network interfaces (the private API endpoint)
#   node:    group on every worker node
# Rules are separate resources because the two groups reference each other.
############################
resource "aws_security_group" "cluster" {
  name_prefix = "${var.name}-cluster-"
  description = "${var.name} EKS control plane (additional security group)"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-cluster-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "node" {
  name_prefix = "${var.name}-node-"
  description = "${var.name} EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-node-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

# --- control plane (cluster group) ---
resource "aws_vpc_security_group_ingress_rule" "cluster_api_from_nodes" {
  security_group_id            = aws_security_group.cluster.id
  referenced_security_group_id = aws_security_group.node.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "Worker nodes to Kubernetes API"
}

# count (not for_each): the group IDs (e.g. the bastion's) are only known after apply
resource "aws_vpc_security_group_ingress_rule" "cluster_api_from_sg" {
  count = length(var.api_allowed_security_group_ids)

  security_group_id            = aws_security_group.cluster.id
  referenced_security_group_id = var.api_allowed_security_group_ids[count.index]
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "Kubernetes API from a trusted security group"
}

resource "aws_vpc_security_group_ingress_rule" "cluster_api_from_cidr" {
  for_each = toset(var.api_allowed_cidrs)

  security_group_id = aws_security_group.cluster.id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "Kubernetes API from ${each.value}"
}

resource "aws_vpc_security_group_egress_rule" "cluster_to_nodes" {
  security_group_id            = aws_security_group.cluster.id
  referenced_security_group_id = aws_security_group.node.id
  ip_protocol                  = "-1"
  description                  = "Control plane to worker nodes (kubelet, webhooks)"
}

# --- worker nodes (node group) ---
resource "aws_vpc_security_group_ingress_rule" "node_from_nodes" {
  security_group_id            = aws_security_group.node.id
  referenced_security_group_id = aws_security_group.node.id
  ip_protocol                  = "-1"
  description                  = "Node to node (pod networking)"
}

resource "aws_vpc_security_group_ingress_rule" "node_from_control_plane" {
  security_group_id            = aws_security_group.node.id
  referenced_security_group_id = aws_security_group.cluster.id
  ip_protocol                  = "-1"
  description                  = "Control plane to nodes"
}

resource "aws_vpc_security_group_egress_rule" "node_all" {
  security_group_id = aws_security_group.node.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Nodes outbound (image pulls through NAT, AWS APIs)"
}
############################
# EKS cluster
############################
resource "aws_eks_cluster" "this" {
  name     = var.name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  enabled_cluster_log_types = var.enabled_log_types

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access ? var.public_access_cidrs : null # only valid with a public endpoint
    security_group_ids      = [aws_security_group.cluster.id]
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  dynamic "encryption_config" {
    for_each = local.kms_arn != null ? [1] : []
    content {
      resources = ["secrets"]
      provider {
        key_arn = local.kms_arn
      }
    }
  }

  tags = merge(var.tags, { Name = var.name })

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy.cluster_kms,
    aws_cloudwatch_log_group.this,
  ]
}

############################
# OIDC provider (enables IAM Roles for Service Accounts)
############################
data "tls_certificate" "oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]

  tags = merge(var.tags, { Name = "${var.name}-oidc" })
}

############################
# Extra cluster admins (EKS access entries)
############################
resource "aws_eks_access_entry" "admin" {
  for_each = var.admin_principals

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin" {
  for_each = var.admin_principals

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.admin]
}

############################
# IAM role for worker nodes (shared by all nodes)
############################
data "aws_iam_policy_document" "assume_ec2" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name_prefix        = "${var.name}-node-role-"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json

  tags = merge(var.tags, { Name = "${var.name}-node-role" })
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each = local.node_policy_arns

  role       = aws_iam_role.node.name
  policy_arn = each.value
}

############################
# One launch template per node: attaches your security groups, encrypts the disk,
# requires IMDSv2 and names the EC2 instance (eks-node-1, eks-node-2, ...).
############################
resource "aws_launch_template" "node" {
  for_each = local.nodes

  name_prefix            = "${each.key}-"
  vpc_security_group_ids = local.node_security_group_ids
  key_name               = var.node_ssh_key_name

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.node_disk_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2 # 2 lets pods reach IMDS if they need to
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = each.key })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(var.tags, { Name = each.key })
  }

  tags = merge(var.tags, { Name = each.key })
}

############################
# One single-node managed node group per node. Nodes are spread across the cluster
# subnets round-robin (node 1 -> subnet 1, node 2 -> subnet 2, ...).
############################
resource "aws_eks_node_group" "this" {
  for_each = local.nodes

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = [var.subnet_ids[(each.value - 1) % length(var.subnet_ids)]]

  ami_type       = var.node_ami_type
  capacity_type  = var.node_capacity_type
  instance_types = var.node_instance_types

  launch_template {
    id      = aws_launch_template.node[each.key].id
    version = aws_launch_template.node[each.key].latest_version
  }

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  labels = merge(var.node_labels, { "node-name" = each.key })

  tags = merge(var.tags, { Name = each.key })

  depends_on = [aws_iam_role_policy_attachment.node]
}

############################
# IRSA roles for add-ons that need AWS API access
############################
data "aws_iam_policy_document" "irsa_assume" {
  for_each = local.irsa_roles

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url_bare}:sub"
      values   = ["system:serviceaccount:${each.value.namespace}:${each.value.service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url_bare}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "irsa" {
  for_each = local.irsa_roles

  name_prefix        = "${var.name}-${each.key}-"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume[each.key].json

  tags = merge(var.tags, { Name = "${var.name}-${each.key}-irsa" })
}

resource "aws_iam_role_policy_attachment" "irsa" {
  for_each = local.irsa_roles

  role       = aws_iam_role.irsa[each.key].name
  policy_arn = each.value.policy_arn
}

############################
# EKS managed add-ons (after the nodes: CoreDNS and the EBS CSI controller need nodes to schedule on)
############################
resource "aws_eks_addon" "this" {
  for_each = var.addons

  cluster_name = aws_eks_cluster.this.name
  addon_name   = each.key

  # null = EKS picks the default version for the cluster's Kubernetes version
  addon_version = each.value.addon_version

  service_account_role_arn = (
    each.value.service_account_role_arn != null
    ? each.value.service_account_role_arn
    : try(aws_iam_role.irsa[each.key].arn, null)
  )

  configuration_values = each.value.configuration_values

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = merge(var.tags, { Name = "${var.name}-${each.key}" })

  depends_on = [
    aws_iam_role_policy_attachment.irsa,
    aws_eks_node_group.this,
  ]
}
