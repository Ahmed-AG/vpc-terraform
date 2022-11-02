provider "aws" {
  region = "us-east-1"
}

# terraform {
# backend "local" {
#     path = "./my-vpc.tfstate"
#  }
# }
terraform {
  backend "s3" {
    bucket         = "cdf-terraform-pipeline2-sourcebucket344f418b-13ndz9o2sz27f"
    key            = "terraform.tfstate"
  }
}

module "vpc-nf" {
  source = "./modules/vpc-nf"
  environment_tag = "test"
}

