# main/provider-backend.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

# don't use variables here
  backend "s3" {
    bucket         = "tf-state-backend-chandra-dev"   # <- set to bootstrap output
    key            = "global/terraform.tfstate"
    region         = "us-east-1"
    profile        = "aws-mlops"
    use_lockfile   = true
    dynamodb_table = "tf-state-lock"         # optional, recommended
    encrypt        = true
  }
}
