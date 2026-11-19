output "instance_ids" {
  description = "Instance IDs."
  value       = aws_instance.this[*].id
}

output "private_ips" {
  description = "Private IPs."
  value       = aws_instance.this[*].private_ip
}

output "public_ips" {
  description = "Public IPs (Elastic IPs if created; empty strings if none)."
  value       = var.create_eip ? aws_eip.this[*].public_ip : aws_instance.this[*].public_ip
}

output "ami_id" {
  description = "AMI used."
  value       = local.ami_id
}

output "ssh_user" {
  description = "Default SSH user for the selected OS (ec2-user or ubuntu)."
  value       = local.ssh_user
}

# output "key_name" {
#   description = "Key pair name used by the instances."
#   value       = local.key_name
# }

output "role_arn" {
  description = "Instance IAM role ARN."
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Instance IAM role name."
  value       = aws_iam_role.this.name
}

output "instance_profile_name" {
  description = "Instance profile name."
  value       = aws_iam_instance_profile.this.name
}

output "security_group_id" {
  description = "Security group created for the instance(s)."
  value       = aws_security_group.this.id
}