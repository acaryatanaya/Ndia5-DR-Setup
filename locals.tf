locals {
  name             = "${var.project}-${var.environment}"
  eks_cluster_name = "${local.name}-eks"

  # Everything that must already exist; each one is looked up and checked against the VPC (see main.tf).
  all_subnet_ids = distinct(concat([var.bastion_subnet_id], var.eks_subnet_ids))

  # Facts read from the existing resources.
  subnet_azs = { for id in local.all_subnet_ids : id => data.aws_subnet.this[id].availability_zone }

  rds_address            = try(data.aws_db_instance.replica[0].address, null)
  rds_port               = try(data.aws_db_instance.replica[0].port, null)
  rds_security_group_ids = try(tolist(data.aws_db_instance.replica[0].vpc_security_groups), [])
  ecr_repository_urls    = { for name, repo in data.aws_ecr_repository.this : name => repo.repository_url }

  # Bastion IAM role: SSM access plus read-only EKS / ECR / RDS metadata.
  bastion_managed_policy_arns = concat(
    ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"],
    var.bastion_extra_policy_arns
  )

  bastion_inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EksReadAndKubeconfig"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:ListNodegroups",
          "eks:DescribeNodegroup",
          "eks:AccessKubernetesApi",
          "eks:ListPodIdentityAssociations",
        ]
        Resource = "*"
      },
      {
        Sid      = "EcrLogin"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "EcrRead"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:DescribeImages",
          "ecr:ListImages",
        ]
        Resource = "*"
      },
      {
        Sid      = "RdsDescribe"
        Effect   = "Allow"
        Action   = ["rds:Describe*"]
        Resource = "*"
      },
    ]
  })
}
