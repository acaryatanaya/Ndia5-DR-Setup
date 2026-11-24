# Terraform loads terraform.tfvars automatically.
# Everything under "Existing ..." is only LOOKED UP; Terraform never creates or deletes it.

region      = "ap-south-2" # Hyderabad
project     = "Ndia5"
environment = "DR" # dev or uat; must match the folder in backend.tf (key = "dev/...") and your IAM policy prefix


# ---------- Existing VPC (replace with your real IDs) ----------
# Find them:  aws ec2 describe-subnets --region ap-south-2 --filters Name=vpc-id,Values=<vpc-id> \
#               --query "Subnets[].[SubnetId,AvailabilityZone,CidrBlock,MapPublicIpOnLaunch,Tags[?Key=='Name']|[0].Value]" --output table
#             aws ec2 describe-security-groups --region ap-south-2 --filters Name=vpc-id,Values=<vpc-id> \
#               --query "SecurityGroups[].[GroupId,GroupName,Description]" --output table
vpc_id = "vpc-022fe7aef0ac46dfb"

platform_codebuild_security_group_id = "sg-013350a64710b2203"

platform_codebuild_role_arn = "arn:aws:iam::074235798563:role/service-role/codebuild-Ndia5-DR-EKS-Platform-Build-service-role"

# ---------- Subnets: one setting per resource ----------
bastion_subnet_id = "subnet-02f2d55a30e7e72c8" # 1 PRIVATE subnet (needs a NAT route for first-boot downloads)
eks_subnet_ids = [                             # your 3 subnets, shared by the EKS control plane AND the worker nodes
  "subnet-03ee15f47db2deca5",
  "subnet-05422a5e8920e74f1",
  "subnet-09f221c48d696cec2",
]

# ---------- Security groups: one setting per resource ----------
bastion_ssh_allowed_cidrs = ["10.220.1.6/32"] # your VPC CIDR, VPN or office range (never 0.0.0.0/0)

# ---------- Existing services (replace with your real names) ----------
rds_replica_identifier = "ndia5-postgresql-db-prod-hyd-read-replica" # DB instance identifier of the replica in Hyderabad. null to skip.
ecr_repository_names = [
  "ndia5/backend-prod",
  "ndia5/frontend-prod",
  "ndia5/report-scheduler-prod",
  "ndia5/transaction-scheduler-prod"
]                            

allow_bastion_to_rds = false # true = add a rule to the RDS security group for the bastion

# ---------- Bastion (Ubuntu 22.04) ----------
bastion_instance_type    = "t3.medium" # t3a.medium = 2 vCPU, 4 GiB RAM, EBS only. t3a.small = 2 vCPU, 2 GiB RAM, EBS only. t3a.micro = 2 vCPU, 1 GiB RAM, EBS only.
bastion_root_volume_size = 30           # GiB, always encrypted


enable_ebs_encryption_by_default = true # true = encrypt every new EBS volume in this region/account

# ---------- EKS: private endpoint only (no public access) ----------

create_eks               = true
eks_version              = "1.35"         
eks_admin_principal_arns = ["arn:aws:iam::074235798563:user/Saurabh_Sawarkar","arn:aws:iam::074235798563:user/Tejas_Dane"]             # extra admin IAM role/user ARNs (the bastion role is added automatically)
eks_node_group_name = "eks-node-group"
eks_node_instance_types = ["t3.medium"]
eks_node_capacity_type  = "ON_DEMAND"
eks_node_disk_size      = 80

# Initial capacity. Cluster Autoscaler will manage desired capacity later.
eks_node_min_size     = 1
eks_node_desired_size = 1
eks_node_max_size     = 3

eks_addons = {
  "vpc-cni"                = {}
  "coredns"                = {}
  "kube-proxy"             = {}
  "aws-ebs-csi-driver"     = {}
  "eks-pod-identity-agent" = {}
  "metrics-server"         = {}
}

nlb_subnet_mappings = [
  {
    subnet_id     = "subnet-0921a69d79f3c5adf"
    allocation_id = "eipalloc-0d5cf3ee825c6d1a8"
  },
  {
    subnet_id     = "subnet-07f68f15052acf0eb"
    allocation_id = "eipalloc-05718f7309bc6b729"
  }
]