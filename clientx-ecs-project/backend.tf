# store the terraform state file in s3
terraform {
  backend "s3" {
    bucket  = "atto-terraform-remote-state-file"
    key     = "clientx-ecs-project.tfstate"
    region  = "us-east-1"
    profile = "terraformDev"
  }
}
