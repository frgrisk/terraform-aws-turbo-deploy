terraform {
  backend "s3" {
    bucket         = "${bucket_name}"
    key            = "terraform-backend/terraform.tfstate"
    region         = "${region}"
    dynamodb_table = "${dynamodb_table}"
    encrypt        = true
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "${region}"
}

variable "aws_region" {
  description = "The AWS region to deploy resources into"
  type = string
  default = "${region}"
}

variable "security_group_id" {
  description = "id of security group associated with ec2 deployment"
  type        = string
  default = "${security_group_id_input}"
}

variable "public_subnet_id" {
  description = "ids of public subnet associated with ec2 deployment"
  type        = string
  default = "${public_subnet_id_input}"
}
