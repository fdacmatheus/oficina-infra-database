terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # State remoto: o repositorio de infraestrutura do Kubernetes le os outputs
  # daqui via terraform_remote_state, e o CI/CD roda em runners efemeros.
  backend "s3" {
    bucket         = "oficina-tfstate-679445922616"
    key            = "database/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "oficina-tflock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "oficina"
      Phase     = "fase-3"
      ManagedBy = "terraform"
      Repo      = "oficina-infra-database"
    }
  }
}
