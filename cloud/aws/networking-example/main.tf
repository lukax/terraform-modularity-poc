terraform {
  backend "s3" {
    bucket = "example-tfstates"
    key    = "networking-exmaple"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.63"
    }
  }

}

locals {
  region_a_ami      = "ami-48351d32"
  region_b_ami      = "ami-f7383a97"
  region_key_pair   = "ccnetkeypair"
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
