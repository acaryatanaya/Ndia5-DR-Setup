############################
# Cluster
############################
variable "name" {
  description = "EKS cluster name (also the prefix for the IAM roles, KMS alias, log group and add-on roles)."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version. Check supported versions: https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html"
  type        = string
  default     = "1.34"
}

variable "subnet_ids" {
  description = "Existing subnets shared by the control plane network interfaces and the worker nodes. At least 2 availability zones. Nodes are spread across them round-robin."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "EKS requires subnets in at least 2 availability zones."
  }
}

variable "endpoint_private_access" {
  description = "Enable the private API endpoint."
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable the public API endpoint. Off by default: the API is reachable only from inside the VPC."
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint (only used when endpoint_public_access = true)."
  type        = list(string)
  default     = []
}

variable "enabled_log_types" {
  description = "Control plane log types to ship to CloudWatch."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "log_retention_days" {
  description = "CloudWatch log retention."
  type        = number
  default     = 30
}

variable "create_kms_key" {
  description = "Create a KMS key for Kubernetes secrets encryption."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Use an existing KMS key ARN for secrets encryption instead of creating one."
  type        = string
  default     = null
}

variable "admin_principals" {
  description = "IAM role/user ARNs granted cluster-admin via EKS access entries, as { label = arn }. Labels must be known at plan time; ARNs may be unknown until apply. (The cluster creator is already admin.)"
  type        = map(string)
  default     = {}
}

############################
# Worker nodes (one single-node managed group per node: eks-node-1, eks-node-2, ...)
############################
variable "vpc_id" {
  description = "VPC in which the cluster and node security groups are created."
  type        = string
}

variable "api_allowed_security_group_ids" {
  description = "Security groups allowed to reach the Kubernetes API (443), e.g. the bastion's."
  type        = list(string)
  default     = []
}

variable "api_allowed_cidrs" {
  description = "CIDR ranges allowed to reach the Kubernetes API (443), e.g. a VPN range."
  type        = list(string)
  default     = []
}

variable "node_count" {
  description = "Number of worker nodes. Each node gets its own single-node group."
  type        = number
  default     = 2

  validation {
    condition     = var.node_count >= 1
    error_message = "node_count must be >= 1."
  }
}

variable "node_name_prefix" {
  description = "Node name prefix. Nodes are named <prefix>-1, <prefix>-2, ..."
  type        = string
  default     = "eks-node"
}

variable "node_instance_types" {
  description = "Instance types. Avoid t2/t3.micro: they allow only 4 pods per node."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "node_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "node_ami_type" {
  description = "Node AMI type."
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "node_disk_size" {
  description = "Node root disk size (GiB). Always encrypted."
  type        = number
  default     = 30
}

variable "node_labels" {
  description = "Kubernetes labels for the nodes."
  type        = map(string)
  default     = {}
}

variable "node_additional_policy_arns" {
  description = "Extra managed policies for the node role (e.g. AmazonSSMManagedInstanceCore)."
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
}

variable "node_ssh_key_name" {
  description = "EC2 key pair for SSH to nodes. Null disables SSH key login (use SSM Session Manager instead)."
  type        = string
  default     = null
}

############################
# Add-ons
############################
variable "addons" {
  description = <<-EOT
    EKS managed add-ons, keyed by add-on name. Set addon_version = null to use the EKS default.
    IRSA roles are created automatically for vpc-cni and aws-ebs-csi-driver.
  EOT
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

variable "tags" {
  description = "Extra tags."
  type        = map(string)
  default     = {}
}
