
locals {
  common_tags = merge(
    {
      Name        = var.name
      Environment = "DR"
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

data "aws_eip" "nlb" {
  for_each = {
    for mapping in var.subnet_mappings :
    mapping.allocation_id => mapping
  }

  id = each.key
}

# ---------------------------------------------------------
# NLB Security Group
# ---------------------------------------------------------

resource "aws_security_group" "nlb" {
  name        = "${var.name}-SG"
  description = "Security group for ${var.name}"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTPS traffic to NLB"

    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-SG"
  })
}

# ---------------------------------------------------------
# Network Load Balancer
# ---------------------------------------------------------

resource "aws_lb" "nlb" {
  name               = var.name
  internal           = false
  load_balancer_type = "network"
  ip_address_type    = "ipv4"

  enable_cross_zone_load_balancing = true

  security_groups = [
    aws_security_group.nlb.id
  ]

  dynamic "subnet_mapping" {
    for_each = var.subnet_mappings

    content {
      subnet_id     = subnet_mapping.value.subnet_id
      allocation_id = subnet_mapping.value.allocation_id
    }
  }

  tags = local.common_tags
}

# ---------------------------------------------------------
# NLB Target Group
# Target type ALB - ALB registration happens later
# ---------------------------------------------------------

resource "aws_lb_target_group" "alb" {
  name        = "${var.name}-TG"
  port        = 443
  protocol    = "TCP"
  target_type = "alb"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    protocol            = var.health_check_protocol
    port                = "traffic-port"
    path                = var.health_check_path
    matcher             = var.health_check_matcher
    interval            = 30
    timeout             = 6
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-TG"
  })
}

# ---------------------------------------------------------
# NLB TCP 443 Listener
# ---------------------------------------------------------

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb.arn
  }

  tags = local.common_tags
}
