terraform {
  required_version = ">= 1.17.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.61.0, < 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4"
    }
  }

  # Remote state: see backend.tf
}

provider "aws" {
  region = var.region

  default_tags {
    tags = merge(
      {
        Project     = var.project
        Environment = var.environment
        ManagedBy   = "terraform"
      },
      var.tags
    )
  }
}
