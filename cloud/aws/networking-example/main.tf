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
      configuration_aliases = [ aws.east, aws.west ]
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  alias   = "east"
  region  = "us-east-1"
}

provider "aws" {
  alias   = "west"
  region  = "us-west-1"
}

module "networking-example-region-east" {
  source = "./region-east"
  providers = {
    aws = aws.east
  }

  region_ami      = "ami-48351d32"
  region_key_pair   = "ccnetkeypair"
}

module "networking-example-region-west" {
  source = "./region-west"
  providers = {
    aws = aws.west
  }

  region_ami      = "ami-f7383a97"
  region_key_pair   = "ccnetkeypair"
}