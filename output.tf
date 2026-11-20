############################
# Existing resources (looked up)
############################
output "vpc_id" {
  description = "Existing VPC ID."
  value       = data.aws_vpc.this.id
}

output "subnet_azs" {
  description = "Availability zone of every existing subnet in use."
  value       = local.subnet_azs
}

output "security_groups_created" {
  description = "Security groups created by the modules."
  value = {
    bastion     = module.ec2.security_group_id
    eks_cluster = try(module.eks_cluster[0].cluster_additional_security_group_id, null)
    eks_nodes   = try(module.eks_cluster[0].node_security_group_id, null)
  }
}

output "rds_replica_endpoint" {
  description = "RDS replica endpoint (null if rds_replica_identifier is not set)."
  value       = local.rds_address
}

output "rds_replica_port" {
  description = "RDS replica port."
  value       = local.rds_port
}

output "ecr_repository_urls" {
  description = "ECR repository URLs in this region."
  value       = local.ecr_repository_urls
}

############################
# Bastion (private: no public IP)
############################
output "bastion_instance_id" {
  description = "Bastion instance ID."
  value       = module.ec2.instance_ids[0]
}

output "bastion_private_ip" {
  description = "Bastion private IP (reachable only from inside the VPC / VPN / peering, or through SSM)."
  value       = module.ec2.private_ips[0]
}

# output "bastion_ssh_commands" {
#   description = "Run from a host that can reach the VPC (VPN, Direct Connect, peering). One per password user, plus the key-based ubuntu user."
#   value = concat(
#     [for u in nonsensitive(keys(var.bastion_users)) : "ssh ${u}@${module.ec2.private_ips[0]}   # password login"],
#     ["ssh -i <your-private-key> ubuntu@${module.ec2.private_ips[0]}   # key login"]
#   )
# }

# output "bastion_ssh_commands" {
#   description = "SSH into the private bastion using the Ubuntu user and your private key."
#   value       = "ssh -i <your-private-key> ubuntu@${module.ec2.private_ips[0]}"
# }

output "bastion_ssm_command" {
  description = "No VPN? Open a shell through SSM Session Manager (needs NAT or SSM VPC endpoints)."
  value       = "aws ssm start-session --region ${var.region} --target ${module.ec2.instance_ids[0]}"
}

# output "bastion_ssm_ssh_tunnel" {
#   description = "SSH over SSM: forwards local port 2222 to the bastion's port 22, then 'ssh -p 2222 user1@localhost'."
#   value       = "aws ssm start-session --region ${var.region} --target ${module.ec2.instance_ids[0]} --document-name AWS-StartPortForwardingSession --parameters portNumber=22,localPortNumber=2222"
# }

output "bastion_role_arn" {
  description = "IAM role of the bastion."
  value       = module.ec2.role_arn
}

output "bastion_bootstrap_log" {
  description = "Where to look if a tool is missing after first boot."
  value       = "sudo tail -n 100 /var/log/bastion-bootstrap.log   (on the bastion)"
}

############################
# EKS (private endpoint: kubectl only works from inside the VPC, e.g. the bastion)
############################
output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = try(module.eks_cluster[0].cluster_name, null)
}

output "eks_cluster_endpoint" {
  description = "EKS API endpoint (resolves to private IPs inside the VPC only)."
  value       = try(module.eks_cluster[0].cluster_endpoint, null)
}

output "eks_node_group_names" {
  description = "EKS node names (eks-node-1, eks-node-2, ...)."
  value       = try(module.eks_cluster[0].node_group_names, null)
}

# output "eks_kubeconfig_command" {
#   description = "Run this ON THE BASTION (the API has no public access). It runs automatically at each user's first login."
#   value       = var.create_eks ? "aws eks update-kubeconfig --region ${var.region} --name ${local.eks_cluster_name}" : null
# }

output "eks_kubeconfig_command" {
  description = "EKS kubeconfig command. Automatically configured during bastion bootstrap."
  value = var.create_eks ? (
    "aws eks update-kubeconfig --region ${var.region} --name ${module.eks_cluster[0].cluster_name}"
  ) : null
}


############################################
# EKS Platform Integration Contract
############################################

output "eks_cluster_arn" {
  description = "EKS cluster ARN."
  value       = try(module.eks_cluster[0].cluster_arn, null)
}

output "eks_cluster_version" {
  description = "Kubernetes version of the EKS cluster."
  value       = try(module.eks_cluster[0].cluster_version, null)
}

output "eks_cluster_ca_data" {
  description = "Base64 encoded EKS cluster certificate authority data."
  value       = try(module.eks_cluster[0].cluster_certificate_authority_data, null)
}

output "eks_oidc_provider_arn" {
  description = "IAM OIDC provider ARN used for IRSA."
  value       = try(module.eks_cluster[0].oidc_provider_arn, null)
}

output "eks_oidc_provider_url" {
  description = "OIDC issuer URL without https://."
  value       = try(module.eks_cluster[0].oidc_provider_url, null)
}

output "eks_node_group_arns" {
  description = "EKS managed node group ARNs."
  value       = try(module.eks_cluster[0].node_group_arns, [])
}

output "eks_node_role_arn" {
  description = "IAM role ARN associated with EKS worker nodes."
  value       = try(module.eks_cluster[0].node_role_arn, null)
}

############################################
# Platform Metadata
############################################

output "aws_region" {
  description = "AWS region where infrastructure is deployed."
  value       = var.region
}

output "project_name" {
  description = "Infrastructure project name."
  value       = var.project
}

output "deployment_environment" {
  description = "Infrastructure deployment environment."
  value       = var.environment
}
