terraform {
  backend "s3" {
    bucket       = "ndia5-dr-terraform-state"
    key          = "ndia5/dr/terraform.tfstate"
    region       = "ap-south-2"
    encrypt      = true
    use_lockfile = true
  }
}