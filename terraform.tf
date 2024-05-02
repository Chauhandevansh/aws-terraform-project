terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.43.0"
    }
  }
  backend "s3" {
    bucket = "tfproject-state-bucket"
    key = "terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "tf-demo-state-table"
  } 
}