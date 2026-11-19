############################
# Existing network and services: read-only lookups, nothing here creates or changes anything.
# Each lookup also checks that the resource belongs to the configured VPC, so a typo or a
# wrong-VPC ID fails at plan time.
############################
data "aws_vpc" "this" {
  id = var.vpc_id
}

data "aws_subnet" "this" {
  for_each = toset(local.all_subnet_ids)

  id = each.value

  lifecycle {
    postcondition {
      condition     = self.vpc_id == var.vpc_id
      error_message = "Subnet ${self.id} belongs to ${self.vpc_id}, not to the configured VPC ${var.vpc_id}."
    }
  }
}

# RDS read replica and replicated ECR repositories. Terraform fails at plan time if a name does not
# exist, which doubles as a check that the replication has really arrived in this region.
data "aws_db_instance" "replica" {
  count = var.rds_replica_identifier != null ? 1 : 0

  db_instance_identifier = var.rds_replica_identifier
}

data "aws_ecr_repository" "this" {
  for_each = toset(var.ecr_repository_names)

  name = each.value
}

############################
# Guards for EKS (fail at plan time with a clear message)
############################
resource "terraform_data" "eks_prereqs" {
  count = var.create_eks ? 1 : 0

  lifecycle {
    precondition {
      condition     = length(distinct([for id in var.eks_subnet_ids : local.subnet_azs[id]])) >= 2
      error_message = "eks_subnet_ids must contain subnets in at least 2 different availability zones."
    }
    precondition {
      condition     = data.aws_vpc.this.enable_dns_support && data.aws_vpc.this.enable_dns_hostnames
      error_message = "The VPC must have DNS support and DNS hostnames enabled. A private-only EKS endpoint cannot be resolved without them."
    }
  }
}

############################
# Optional: account-wide "EBS encryption by default" for this region
############################
resource "aws_ebs_encryption_by_default" "this" {
  count = var.enable_ebs_encryption_by_default ? 1 : 0

  enabled = true
}

############################
# Bastion server (modules/EC-2): Ubuntu 22.04, key pair, IAM role + profile, encrypted root volume,
# users + AWS CLI + kubectl + eksctl via user data. Uses YOUR existing private subnet and security
# group(s); nothing is created for networking.
############################
module "ec2" {
  source = "./modules/EC-2"

  name           = "${local.name}-bastion"
  instance_count = 1
  instance_type  = var.bastion_instance_type
  os             = "ubuntu-22.04"
  ami_id         = var.bastion_ami_id

  subnet_ids          = [var.bastion_subnet_id]
  vpc_id              = var.vpc_id
  ssh_allowed_cidrs   = var.bastion_ssh_allowed_cidrs
  associate_public_ip = false # private subnet: no public IP, no Elastic IP
  create_eip          = false
  root_volume_size    = var.bastion_root_volume_size # encrypted with the default EBS key by the module

  # Key pair: your own public key
  create_key_pair   = var.create_key_pair
  existing_key_name = var.existing_key_name
  key_name          = "${local.name}-key"
  public_key        = var.public_key

  # IAM role + instance profile
  iam_managed_policy_arns = local.bastion_managed_policy_arns
  iam_inline_policy_json  = local.bastion_inline_policy

  # First-boot bootstrap
  region           = var.region
  eks_cluster_name = var.create_eks ? module.eks_cluster[0].cluster_name : ""
  kubectl_minor    = var.eks_version
  extra_packages   = var.bastion_extra_packages

  depends_on = [data.aws_subnet.this]
}

############################
# Optional: let the bastion reach the RDS replica (adds a rule to the existing SG)
############################
resource "aws_vpc_security_group_ingress_rule" "bastion_to_rds" {
  for_each = var.allow_bastion_to_rds ? toset(local.rds_security_group_ids) : toset([])

  security_group_id            = each.value
  referenced_security_group_id = module.ec2.security_group_id
  ip_protocol                  = "tcp"
  from_port                    = local.rds_port
  to_port                      = local.rds_port
  description                  = "Bastion access to RDS replica"
}

############################
# EKS (modules/EKS-CLUSTER): private endpoint only; control plane and nodes share eks_subnet_ids
############################
module "eks_cluster" {
  source = "./modules/EKS-CLUSTER"
  count  = var.create_eks ? 1 : 0

  name            = local.eks_cluster_name
  cluster_version = var.eks_version
  subnet_ids      = var.eks_subnet_ids # control plane network interfaces AND worker nodes

  # Private only: the API is reachable from inside the VPC (the bastion), never from the internet.
  endpoint_private_access = true
  endpoint_public_access  = false

  vpc_id                         = var.vpc_id
  api_allowed_security_group_ids = [module.ec2.security_group_id] # the bastion may reach the API (443)
  enabled_log_types              = var.eks_enabled_log_types

  # Static keys (values may be unknown until apply), so for_each works on the first run.
  admin_principals = merge(
    { for i, arn in var.eks_admin_principal_arns : "extra-${i}" => arn },
    { bastion = module.ec2.role_arn }
  )

  # Worker nodes: eks-node-1, eks-node-2, ... (the EKS cluster security group is added automatically)
  node_instance_types = var.eks_node_instance_types
  node_capacity_type  = var.eks_node_capacity_type
  node_disk_size      = var.eks_node_disk_size
  node_count          = var.eks_node_count
  node_name_prefix    = var.eks_node_name_prefix

  addons = var.eks_addons

  depends_on = [terraform_data.eks_prereqs]
}
# EKS creates its own cluster security group (attached to the control plane and the nodes).
############################################
# AWS Secrets Manager + ESO IAM integration
############################################

module "secret_manager" {
  source = "./modules/SECRET-MANAGER"
  count  = var.create_eks ? 1 : 0

  region = var.region

  role_name = "${local.eks_cluster_name}-eso-role"

  cluster_name = module.eks_cluster[0].cluster_name
  cluster_arn  = module.eks_cluster[0].cluster_arn

  namespace       = "external-secrets"
  service_account = "external-secrets"

  secret_definitions = var.external_secret_definitions

  kms_key_arn = var.secrets_manager_kms_key_arn

  tags = var.tags

  depends_on = [
    module.eks_cluster
  ]
}