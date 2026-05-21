# Esto le dice a Terraform: "vamos a trabajar con AWS"

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Tags que se aplican automáticamente a TODOS los recursos creados
  default_tags {
    tags = {
      Project     = "interoperabilidad-sistema-salud"
      Environment = var.environment
      ManagedBy   = "terraform"
      Team        = "viaja-seguro"
    }
  }
}