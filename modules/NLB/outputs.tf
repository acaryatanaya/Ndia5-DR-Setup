
output "nlb_arn" {
  description = "ARN of the Network Load Balancer."
  value       = aws_lb.nlb.arn
}

output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer."
  value       = aws_lb.nlb.dns_name
}

output "nlb_zone_id" {
  description = "Canonical hosted zone ID of the NLB."
  value       = aws_lb.nlb.zone_id
}

output "nlb_security_group_id" {
  description = "Security group ID attached to the NLB."
  value       = aws_security_group.nlb.id
}

output "nlb_target_group_arn" {
  description = "ARN of the ALB-type NLB target group."
  value       = aws_lb_target_group.alb.arn
}

output "nlb_listener_arn" {
  description = "ARN of the TCP 443 listener."
  value       = aws_lb_listener.https.arn
}

output "nlb_eip_allocation_ids" {
  description = "Elastic IP allocation IDs configured on the NLB."
  value = [
    for mapping in var.subnet_mappings :
    mapping.allocation_id
  ]
}

output "nlb_public_ips" {
  description = "Static public Elastic IP addresses assigned to the NLB."

  value = [
    for mapping in var.subnet_mappings :
    data.aws_eip.nlb[mapping.allocation_id].public_ip
  ]
}
