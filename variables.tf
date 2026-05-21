variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "interoperabilidad-sistema-salud"
}

# Bucket donde los CI de las Lambdas suben los .zip
variable "artifact_bucket" {
  description = "Bucket S3 donde están los .zip de las Lambdas"
  type        = string
  default     = "interoperabilidad-sistema-salud"
}