# IMP: Variable names always with "_", not "-". HCL interprets in a wrong way like args.

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "profile" {
  type    = string
  default = "aws-mlops"
}

variable "tf_state_backend_s3" {
  type    = string
  default = "tf-state-backend-chandra-dev"
}

variable "dynamodb_table" {
  type    = string
  default = "tf-state-lock"
}
