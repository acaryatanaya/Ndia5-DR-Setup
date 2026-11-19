locals {
  # Ubuntu AMIs come from Canonical's AWS account (searched by name, so it works in any
  # region where Canonical publishes). Amazon Linux uses the public SSM parameter.
  os_catalog = {
    "amazon-linux" = {
      ssh_user    = "ec2-user"
      name_filter = ""
    }
    "ubuntu-24.04" = {
      ssh_user    = "ubuntu"
      name_filter = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
    }
    "ubuntu-22.04" = {
      ssh_user    = "ubuntu"
      name_filter = "ubuntu/images/hvm-ssd*/ubuntu-jammy-22.04-amd64-server-*"
    }
  }

  is_ubuntu = startswith(var.os, "ubuntu")
  ssh_user  = local.os_catalog[var.os].ssh_user

  ami_id = (
    var.ami_id != null ? var.ami_id :
    local.is_ubuntu ? data.aws_ami.ubuntu[0].id :
    data.aws_ssm_parameter.al2023[0].value
  )

  # key_pair_name = coalesce(var.key_name, "${var.name}-key")
  # key_name      = var.create_key_pair ? aws_key_pair.this[0].key_name : var.existing_key_name


  # First-boot script: installs AWS CLI, kubectl, eksctl, Helm
  # and configures EKS kubeconfig automatically.
  user_data = trimspace(templatefile(
    "${path.module}/bastion-userdata.sh.tftpl",
    {
      region           = var.region
      eks_cluster_name = var.eks_cluster_name
      kubectl_minor    = var.kubectl_minor
      helm_version     = var.helm_version
      extra_packages   = join(" ", var.extra_packages)
    }
  ))


}
