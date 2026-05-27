terraform {
  backend "s3" {
    key            = "aws-app-janitor/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "jit-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      project = "jit-access-poc"
      stack   = "aws-app-janitor"
      team    = "platform"
    }
  }
}
