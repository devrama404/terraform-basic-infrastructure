terraform {
required_version = ">= 1.0"

required_providers {
aws = {
source = "hashicorp/aws"
version = "~> 5.0"
}
}
}

############################
# AWS Provider
############################

provider "aws" {
region = var.aws_region
}

############################
# Ubuntu 24.04 LTS AMI
############################

data "aws_ami" "ubuntu" {
most_recent = true

owners = ["099720109477"] # Canonical

filter {
name = "name"
values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
}

filter {
name = "virtualization-type"
values = ["hvm"]
}
}

############################
# EC2 Instance
############################

resource "aws_instance" "web" {
ami = data.aws_ami.ubuntu.id
instance_type = var.instance_type

tags = {
Name = "Terraform-EC2"
Environment = "Lab"
Project = "Terraform-Basic-Infrastructure"
}
}

############################
# Elastic IP
############################

resource "aws_eip" "web_eip" {
instance = aws_instance.web.id
domain = "vpc"

tags = {
Name = "Terraform-EIP"
Environment = "Lab"
Project = "Terraform-Basic-Infrastructure"
}
}

############################
# S3 Bucket
############################

resource "aws_s3_bucket" "storage" {
bucket = var.bucket_name

tags = {
Name = "Terraform-Bucket"
Environment = "Lab"
Project = "Terraform-Basic-Infrastructure"
}
}
