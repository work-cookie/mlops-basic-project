# bootstrap/bootstrap.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.profile
}

/*locals {
  tf_state_bucket_name = "tf-state-bucket-terraform-backend-${var.profile}-${replace(uuid(),\"-\",\"\")}"
  dynamodb_table_name  = "tf-state-lock-table-${replace(uuid(),\"-\",\"\")}"
}*/

# S3 bucket for remote state
resource "aws_s3_bucket" "tf_state_bucket" {
  bucket = var.tf_state_backend_s3

  tags = {
    Name = "terraform-state-backend"
    Environment = "dev"
  }
}

# Optional DynamoDB table for state locking (recommended)
resource "aws_dynamodb_table" "tf_lock" {
  name         = var.dynamodb_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "tf-state-lock"
  }
}

output "tf_state_bucket" {
  value = aws_s3_bucket.tf_state_bucket.bucket
}

output "dynamodb_table" {
  value = aws_dynamodb_table.tf_lock.name
}
