# Terraform loads terraform.tfvars automatically.
# Everything under "Existing ..." is only LOOKED UP; Terraform never creates or deletes it.

region      = "ap-south-2" # Hyderabad
project     = "Ndia5"
environment = "DR" # dev or uat; must match the folder in backend.tf (key = "dev/...") and your IAM policy prefix

tags = {
  Owner = "saurabh"
}

# ---------- Existing VPC (replace with your real IDs) ----------
# Find them:  aws ec2 describe-subnets --region ap-south-2 --filters Name=vpc-id,Values=<vpc-id> \
#               --query "Subnets[].[SubnetId,AvailabilityZone,CidrBlock,MapPublicIpOnLaunch,Tags[?Key=='Name']|[0].Value]" --output table
#             aws ec2 describe-security-groups --region ap-south-2 --filters Name=vpc-id,Values=<vpc-id> \
#               --query "SecurityGroups[].[GroupId,GroupName,Description]" --output table
vpc_id = "vpc-022fe7aef0ac46dfb"

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
]                            # replicated repositories. [] to skip.
allow_bastion_to_rds = false # true = add a rule to the RDS security group for the bastion

# ---------- Key pair (create it yourself, paste the PUBLIC key) ----------
#   ssh-keygen -t ed25519 -f hyd-bastion-key -C "hyd-bastion"
create_key_pair = true
public_key      = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIg7ACyQWiWUOuR+qOAZRAhYocqoTuaQK5xg5SCqPB+6 Ndia5-DR-Bastion" # e.g. "ssh-ed25519 AAAAC3Nza... hyd-bastion"

# ---------- Bastion (Ubuntu 22.04) ----------
bastion_instance_type    = "t3.medium" # t3a.medium = 2 vCPU, 4 GiB RAM, EBS only. t3a.small = 2 vCPU, 2 GiB RAM, EBS only. t3a.micro = 2 vCPU, 1 GiB RAM, EBS only.
bastion_root_volume_size = 30           # GiB, always encrypted

# Two users that log in with SSH + password. Rename them as you like.
# Generate each hash (you type the password when prompted):   openssl passwd -6
# Paste the full result (starts with $6$). Never put a plain password here.
bastion_users = {
  admin = {
    password_hash = "$6$UMSQw6PacImW2Dg7$SuwtMAdPiY3bQooyWPtABYnd87d61bFXPZ.G1ADguVxrdPWOodOJhId6jdOekKvtdQELeVqvo5JJQCnvElMe21"
    sudo          = true # true = user can run sudo
  }
  psspl = {
    password_hash = "$6$vXsjd9Z4GTBfwoUI$GSJ/UO17WF3eZts5d/XVssVwvnkYQmj9KlxqjmHkWD9gYv2nBr1vv7VUnDwW7yRtCeEKz5uBQ2SFHKj8Yl5yj."
    sudo          = true
  }
}

# bastion_extra_packages    = ["postgresql-client"] # or ["mysql-client"], to reach the RDS replica
# bastion_extra_policy_arns = []                    # eksctl that CREATES clusters needs much broader rights

enable_ebs_encryption_by_default = true # true = encrypt every new EBS volume in this region/account

# ---------- EKS: private endpoint only (no public access) ----------
# Cost: control plane ~$73/mo + nodes. kubectl/eksctl work only from inside the VPC, i.e. on the bastion.
create_eks               = true
eks_version              = "1.34"         # verify it is currently supported in your region
eks_admin_principal_arns = ["arn:aws:iam::074235798563:user/Saurabh_Sawarkar","arn:aws:iam::074235798563:user/Tejas_Dane"]             # extra admin IAM role/user ARNs (the bastion role is added automatically)
eks_node_instance_types  = ["t3.medium"] # do not use t2/t3.micro: only 4 pods per node
eks_node_capacity_type   = "ON_DEMAND"
eks_node_disk_size       = 80
eks_node_count           = 1 # eks-node-1 -> 1st subnet, eks-node-2 -> 2nd. Set 3 for one node in each of your 3 subnets/AZs
eks_node_name_prefix     = "eks-node"

eks_addons = {
  "vpc-cni"                = {}
  "coredns"                = {}
  "kube-proxy"             = {}
  "aws-ebs-csi-driver"     = {}
  "eks-pod-identity-agent" = {}
}
