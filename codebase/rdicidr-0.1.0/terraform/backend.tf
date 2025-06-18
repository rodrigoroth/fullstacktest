terraform {
  backend "s3" {
    bucket       = "my-fullstack-labs-terraform-states"
    key          = "terraform/state/devel/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
