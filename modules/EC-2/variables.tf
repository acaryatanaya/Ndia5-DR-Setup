############################
# General
############################
variable "name" {
  description = "Name prefix (instance, IAM role and profile names start with this)."
  type        = string
}

variable "tags" {
  description = "Extra tags."
  type        = map(string)
  default     = {}
}

############################
# Instance
############################
variable "instance_count" {
  description = "Number of instances."
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count >= 0
    error_message = "instance_count must be >= 0."
  }
}

variable "instance_type" {
  description = "Instance type."
  type        = string
  default     = "t3.micro"
}

variable "os" {
  description = "Operating system when ami_id is null: amazon-linux, ubuntu-24.04 or ubuntu-22.04."
  type        = string
  default     = "amazon-linux"

  validation {
    condition     = contains(["amazon-linux", "ubuntu-24.04", "ubuntu-22.04"], var.os)
    error_message = "os must be one of: amazon-linux, ubuntu-24.04, ubuntu-22.04."
  }
}

variable "ami_id" {
  description = "Explicit AMI ID. Null = latest AMI for the selected os. The ssh_user output follows os, so keep os matching a custom AMI."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Existing subnets to spread instances across (round-robin)."
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC in which the instance security group is created."
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = "CIDR ranges allowed to SSH (22) to the instance. Empty = no inbound SSH rule (use SSM Session Manager)."
  type        = list(string)
  default     = []
}

variable "ssh_allowed_security_group_ids" {
  description = "Security groups allowed to SSH (22) to the instance (e.g. a VPN or jump host group)."
  type        = list(string)
  default     = []
}

variable "associate_public_ip" {
  description = "Associate a public IP."
  type        = bool
  default     = false
}

variable "create_eip" {
  description = "Attach an Elastic IP to each instance."
  type        = bool
  default     = false
}

variable "root_volume_size" {
  description = "Root volume size (GiB). Always encrypted (default AWS-managed EBS key)."
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Root volume type."
  type        = string
  default     = "gp3"
}

variable "detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring."
  type        = bool
  default     = false
}

variable "termination_protection" {
  description = "Enable termination protection."
  type        = bool
  default     = false
}

############################
# Key pair (you create the key yourself; paste the PUBLIC key)
############################
variable "create_key_pair" {
  description = "Upload public_key as a new key pair. If false, existing_key_name must be set."
  type        = bool
  default     = true
}

variable "key_name" {
  description = "Name for the created key pair. Default '<name>-key'."
  type        = string
  default     = null
}

variable "existing_key_name" {
  description = "Existing AWS key pair name (used when create_key_pair = false)."
  type        = string
  default     = null
}

variable "public_key" {
  description = "Contents of your .pub file (used when create_key_pair = true)."
  type        = string
  default     = ""
}

############################
# IAM role + instance profile
############################
variable "iam_managed_policy_arns" {
  description = "Managed policy ARNs attached to the instance role."
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
}

variable "iam_inline_policy_json" {
  description = "Optional inline policy document (JSON) for the instance role."
  type        = string
  default     = null
}

############################
# Bootstrap (user data): users, AWS CLI, kubectl, eksctl
############################
variable "region" {
  description = "AWS region written into the users' AWS CLI defaults."
  type        = string
}

variable "users" {
  description = "Users created on the server, keyed by username (SSH + password). password_hash is a SHA-512 crypt hash."
  type = map(object({
    password_hash  = string
    sudo           = optional(bool, false)
    ssh_public_key = optional(string, "")
  }))
  sensitive = true
  default   = {}
}

variable "eks_cluster_name" {
  description = "EKS cluster to auto-configure kubectl for at each user's first login. Empty = none."
  type        = string
  default     = ""
}

variable "kubectl_minor" {
  description = "Kubernetes minor version, e.g. 1.34. The latest patch of this kubectl is installed."
  type        = string
  default     = "1.34"
}

variable "extra_packages" {
  description = "Extra apt packages to install, e.g. [\"postgresql-client\"]."
  type        = list(string)
  default     = []
}
