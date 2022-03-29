provider "aws" {
  region  = "us-east-1"
  profile = "<your-aws-profile>"
}

terraform {
  required_version = ">= 1.0"
  
  #to put the state in a s3 bucket
  # backend "s3" {
  #   bucket  = "terraform"
  #   key     = "terraform.tfstate"
  #   region  = "us-east-1"
  #   profile = "<your-aws-profile>"
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.69.0"
    }
  }
}