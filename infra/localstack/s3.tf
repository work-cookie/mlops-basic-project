resource "aws_s3_bucket" "raw" {
  bucket = "${var.project_name}-raw"
}

resource "aws_s3_bucket" "bronze" {
  bucket = "${var.project_name}-bronze"
}

resource "aws_s3_bucket" "silver" {
  bucket = "${var.project_name}-silver"
}

resource "aws_s3_bucket" "gold" {
  bucket = "${var.project_name}-gold"
}

resource "aws_s3_bucket" "mlflow_artifacts" {
  bucket = "${var.project_name}-mlflow-artifacts"
}

resource "aws_s3_bucket" "feature_store" {
  bucket = "${var.project_name}-feast"
}

resource "aws_s3_bucket" "model_registry" {
  bucket = "${var.project_name}-model-registry"
}
