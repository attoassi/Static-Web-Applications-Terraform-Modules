# store the terraform state file in s3
terraform {
  backend "s3" {
    bucket  = "Your-Bucket-Name"
    key     = "Your-Key-Name"
    region  = "us-east-1"
    profile = "Your-profile-Name"
  }
}
