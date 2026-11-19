############################
# General
############################
variable "region" {
  description = "AWS region."
  type        = string
  default     = "ap-south-2" # Hyderabad
}

variable "project" {
  description = "Project name, used as a resource name prefix and tag."
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)."
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Extra tags applied to everything Terraform creates."
  type        = map(string)
  default     = {}
}

############################
# Existing VPC, subnets and security groups (created outside Terraform, only looked up)
############################
variable "vpc_id" {
  description = "ID of the existing VPC."
  type        = string

  validation {
    condition     = startswith(var.vpc_id, "vpc-")
    error_message = "vpc_id must look like vpc-0123456789abcdef0."
  }
}

# --- Subnets: one setting per resource ---
variable "bastion_subnet_id" {
  description = "Existing PRIVATE subnet for the bastion (no public IP; needs a NAT route or VPC endpoints for first-boot downloads and SSM)."
  type        = string

  validation {
    condition     = startswith(var.bastion_subnet_id, "subnet-")
    error_message = "bastion_subnet_id must look like subnet-0123456789abcdef0."
  }
}

variable "eks_subnet_ids" {
  description = "Existing subnets shared by the EKS control plane and the worker nodes (e.g. your 3 subnets). Must span at least 2 availability zones. Nodes are spread across them in order: eks-node-1 -> first, eks-node-2 -> second, ... (wrapping around). They need a NAT route or VPC endpoints."
  type        = list(string)
  default     = []
}

# --- Security groups ---
variable "bastion_ssh_allowed_cidrs" {
  description = "CIDR ranges allowed to SSH (port 22) to the bastion, e.g. your VPC CIDR, VPN or office range. 0.0.0.0/0 is rejected."
  type        = list(string)

  validation {
    condition     = length(var.bastion_ssh_allowed_cidrs) >= 1 && alltrue([for c in var.bastion_ssh_allowed_cidrs : can(cidrhost(c, 0))])
    error_message = "Provide at least one valid CIDR (e.g. 10.0.0.0/16) for SSH access to the bastion."
  }

  validation {
    condition     = !contains(var.bastion_ssh_allowed_cidrs, "0.0.0.0/0")
    error_message = "Do not open SSH to 0.0.0.0/0. Use your VPC, VPN or office CIDR."
  }
}

variable "eks_node_security_group_ids" {
  description = "Existing security group(s) added to every EKS worker node (the EKS cluster security group is always added too, so nodes can reach the control plane)."
  type        = list(string)
  default     = []
}

############################
# Existing services (RDS replica, ECR) - looked up, not created
############################
variable "rds_replica_identifier" {
  description = "DB instance identifier of the existing RDS read replica in this region. Null = skip."
  type        = string
  default     = null
}

variable "ecr_repository_names" {
  description = "Names of the existing (replicated) ECR repositories in this region."
  type        = list(string)
  default     = []
}

variable "allow_bastion_to_rds" {
  description = "Add an inbound rule (bastion's first security group -> DB port) to the RDS replica's security group(s). This modifies existing security groups. Leave false if your groups already allow it."
  type        = bool
  default     = false
}

############################
# Key pair (you create the key yourself; paste the PUBLIC key)
############################
# variable "create_key_pair" {
#   description = "Upload your public key as a new key pair."
#   type        = bool
#   default     = true
# }

# variable "existing_key_name" {
#   description = "Existing AWS key pair name, used when create_key_pair = false."
#   type        = string
#   default     = null
# }

# variable "public_key" {
#   description = "Contents of your .pub file. Used for the bastion's default 'ubuntu' user."
#   type        = string
#   default     = ""

#   validation {
#     condition     = var.public_key == "" || can(regex("^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp[0-9]+) ", trimspace(var.public_key)))
#     error_message = "public_key must be a valid OpenSSH public key (starts with ssh-ed25519, ssh-rsa or ecdsa-sha2-...). Paste the contents of your .pub file, not the private key."
#   }
# }

############################
# Bastion server (Ubuntu 22.04)
############################

variable "bastion_instance_type" {
  description = "Bastion instance type."
  type        = string
  default     = "t3.medium"
}

variable "bastion_root_volume_size" {
  description = "Bastion root volume size (GiB). The volume is always encrypted (default AWS-managed EBS key)."
  type        = number
  default     = 20
}

variable "bastion_ami_id" {
  description = "Explicit AMI ID. Null = latest Ubuntu 22.04 from Canonical."
  type        = string
  default     = null
}

variable "bastion_extra_packages" {
  description = "Extra apt packages to install, e.g. [\"postgresql-client\"] or [\"mysql-client\"]."
  type        = list(string)
  default     = []
}

variable "bastion_extra_policy_arns" {
  description = "Extra managed IAM policies for the bastion role. The default role can only read EKS/ECR/RDS metadata. eksctl creating clusters needs much broader rights."
  type        = list(string)
  default     = []
}

variable "enable_ebs_encryption_by_default" {
  description = "Turn on 'EBS encryption by default' for the whole account in this region. Affects every new volume in the region, so it is off unless you want it."
  type        = bool
  default     = false
}

############################
# EKS (private endpoint only - there is no public access setting on purpose)
############################
variable "create_eks" {
  description = "Create the EKS cluster, node groups and add-ons in the existing subnets. Control plane costs ~$0.10/hr plus nodes."
  type        = bool
  default     = false
}

variable "eks_version" {
  description = "Kubernetes version. Check currently supported versions in the EKS docs. The bastion installs a matching kubectl."
  type        = string
  default     = "1.34"
}

variable "eks_enabled_log_types" {
  description = "Control plane log types sent to CloudWatch."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "eks_admin_principal_arns" {
  description = "Extra IAM role/user ARNs granted cluster-admin. The Terraform caller and the bastion role are admins automatically."
  type        = list(string)
  default     = []
}

variable "eks_node_instance_types" {
  description = "Worker node instance types. Avoid t2/t3.micro: they allow only 4 pods per node."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_capacity_type" {
  description = "ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"
}

variable "eks_node_disk_size" {
  description = "Worker node disk size (GiB). Always encrypted."
  type        = number
  default     = 30
}

############################
# EKS managed node group scaling
############################

variable "eks_node_group_name" {
  description = "Name of the EKS managed node group."
  type        = string
  default     = "eks-node-group"
}

variable "eks_node_min_size" {
  description = "Minimum number of EKS worker nodes."
  type        = number
  default     = 1

  validation {
    condition     = var.eks_node_min_size >= 1
    error_message = "eks_node_min_size must be at least 1."
  }
}

variable "eks_node_desired_size" {
  description = "Initial desired number of EKS worker nodes."
  type        = number
  default     = 1

  validation {
    condition     = var.eks_node_desired_size >= var.eks_node_min_size
    error_message = "Desired size must be greater than or equal to minimum size."
  }
}

variable "eks_node_max_size" {
  description = "Maximum number of EKS worker nodes."
  type        = number
  default     = 3

  validation {
    condition     = var.eks_node_max_size >= var.eks_node_desired_size
    error_message = "Maximum size must be greater than or equal to desired size."
  }
}

variable "eks_addons" {
  description = "EKS managed add-ons keyed by name. addon_version = null uses the EKS default."
  type = map(object({
    addon_version            = optional(string)
    service_account_role_arn = optional(string)
    configuration_values     = optional(string)
  }))
  default = {
    "vpc-cni"                = {}
    "coredns"                = {}
    "kube-proxy"             = {}
    "aws-ebs-csi-driver"     = {}
    "eks-pod-identity-agent" = {}
  }
}

variable "platform_codebuild_security_group_id" {
  description = "Security group ID attached to the EKS platform CodeBuild project."
  type        = string
}

variable "platform_codebuild_role_arn" {
  description = "IAM role ARN used by the EKS platform CodeBuild project."
  type        = string
}

############################################
# External Secrets / AWS Secrets Manager
############################################

variable "external_secret_definitions" {
  description = "Names and descriptions of AWS Secrets Manager secrets."

  type = map(string)

  default = {
    "ndia5/dr/database" = "NDIA5 DR database credentials"
  }
}

variable "secrets_manager_kms_key_arn" {
  description = "Optional dedicated KMS key ARN for Secrets Manager."
  type        = string
  default     = null
}