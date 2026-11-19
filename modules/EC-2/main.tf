############################
# AMI lookup
############################
# Latest Amazon Linux 2023 AMI (skipped when ami_id is set or an Ubuntu OS is chosen)
data "aws_ssm_parameter" "al2023" {
  count = var.ami_id == null && !local.is_ubuntu ? 1 : 0

  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# Latest Ubuntu AMI from Canonical (skipped when ami_id is set or Amazon Linux is chosen)
data "aws_ami" "ubuntu" {
  count = var.ami_id == null && local.is_ubuntu ? 1 : 0

  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = [local.os_catalog[var.os].name_filter]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ############################
# # Key pair (your own public key)
# ############################
# resource "aws_key_pair" "this" {
#   count = var.create_key_pair ? 1 : 0

#   key_name   = local.key_pair_name
#   public_key = trimspace(var.public_key)

#   tags = merge(var.tags, { Name = local.key_pair_name })
# }

############################
# IAM role + instance profile
############################
data "aws_iam_policy_document" "assume_ec2" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name_prefix        = "${var.name}-ec2-role-"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json

  tags = merge(var.tags, { Name = "${var.name}-ec2-role" })
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.iam_managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  count = var.iam_inline_policy_json != null ? 1 : 0

  name   = "${var.name}-inline"
  role   = aws_iam_role.this.id
  policy = var.iam_inline_policy_json
}

resource "aws_iam_instance_profile" "this" {
  name_prefix = "${var.name}-ec2-profile-"
  role        = aws_iam_role.this.name

  tags = merge(var.tags, { Name = "${var.name}-ec2-profile" })
}

############################
# Security group: SSH in from the allowed ranges, everything out (apt, AWS CLI downloads, SSM)
############################
resource "aws_security_group" "this" {
  name_prefix = "${var.name}-sg-"
  description = "${var.name} instance security group"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh_cidr" {
  for_each = toset(var.ssh_allowed_cidrs)

  security_group_id = aws_security_group.this.id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  description       = "SSH from ${each.value}"
}

# count (not for_each): the group IDs may only be known after apply
resource "aws_vpc_security_group_ingress_rule" "ssh_sg" {
  count = length(var.ssh_allowed_security_group_ids)

  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = var.ssh_allowed_security_group_ids[count.index]
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  description                  = "SSH from a trusted security group"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound"
}
############################
# Instance(s): encrypted root volume, IMDSv2, users + tools via user data
############################
resource "aws_instance" "this" {
  count = var.instance_count

  ami                         = local.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids      = [aws_security_group.this.id]
  # key_name                    = local.key_name
  iam_instance_profile        = aws_iam_instance_profile.this.name
  associate_public_ip_address = var.associate_public_ip
  user_data                   = local.user_data
  user_data_replace_on_change = true
  monitoring                  = var.detailed_monitoring
  disable_api_termination     = var.termination_protection

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    encrypted             = true
    delete_on_termination = true

    tags = merge(var.tags, { Name = "${var.name}-${count.index + 1}-root" })
  }

  tags = merge(var.tags, { Name = "${var.name}-${count.index + 1}" })

  # The instance profile needs its policies before the instance boots and calls AWS.
  depends_on = [aws_iam_role_policy_attachment.managed, aws_iam_role_policy.inline]

  lifecycle {
    ignore_changes = [ami]

    precondition {
      condition     = length(var.subnet_ids) > 0
      error_message = "No subnets given. Set subnet_ids to at least one existing subnet."
    }

    # precondition {
    #   condition     = var.create_key_pair ? trimspace(var.public_key) != "" : var.existing_key_name != null
    #   error_message = "Set public_key (contents of your .pub file) when create_key_pair = true, or existing_key_name when it is false."
    # }
  }
}

resource "aws_eip" "this" {
  count = var.create_eip ? var.instance_count : 0

  domain   = "vpc"
  instance = aws_instance.this[count.index].id

  tags = merge(var.tags, { Name = "${var.name}-eip-${count.index + 1}" })
}
