# main/variables.tf
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "profile" {
  description = "AWS CLI profile name"
  type        = string
  default     = "aws-mlops"
}

variable "vpc_cidr" {
  type    = string
  default = "10.50.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.50.1.0/24"
}

variable "public_subnet_b_cidr" {
  type    = string
  default = "10.50.4.0/24"
}

variable "private_subnet_a_cidr" {
  type    = string
  default = "10.50.2.0/24"
}

variable "private_subnet_b_cidr" {
  type    = string
  default = "10.50.3.0/24"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type    = string
  default = "mlops-keys" # optional: if you want SSH via bastion later
}

variable "app_bucket_name" {
  type    = string
  default = "ch-dvc-storage" # optional; if empty, name will be generated
}
