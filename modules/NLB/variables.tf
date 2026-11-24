
variable "name" {
  description = "Name of the Network Load Balancer."
  type        = string
  default     = "Ndia5-DR-NLB"
}

variable "vpc_id" {
  description = "VPC ID in which the NLB security group is created."
  type        = string
}

variable "subnet_mappings" {
  description = "Public subnet and Elastic IP allocation mapping for the NLB."
  type = list(object({
    subnet_id     = string
    allocation_id = string
  }))

  validation {
    condition     = length(var.subnet_mappings) == 2
    error_message = "Exactly two subnet mappings are required for the Hyderabad NLB."
  }

  validation {
    condition = (
      length(distinct([for mapping in var.subnet_mappings : mapping.subnet_id])) == 2 &&
      length(distinct([for mapping in var.subnet_mappings : mapping.allocation_id])) == 2
    )
    error_message = "Each NLB subnet and Elastic IP allocation must be unique."
  }
}

variable "allowed_cidrs" {
  description = "IPv4 CIDRs permitted to access the NLB listener."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "health_check_path" {
  description = "HTTP/HTTPS health check path used by the NLB target group."
  type        = string
  default     = "/"
}

variable "health_check_protocol" {
  description = "Protocol used for the ALB target health check."
  type        = string
  default     = "HTTPS"

  validation {
    condition     = contains(["HTTP", "HTTPS"], var.health_check_protocol)
    error_message = "Health check protocol must be HTTP or HTTPS."
  }
}

variable "health_check_matcher" {
  description = "HTTP status codes considered healthy."
  type        = string
  default     = "200-499"
}

variable "tags" {
  description = "Tags applied to NLB resources."
  type        = map(string)
  default     = {}
}
