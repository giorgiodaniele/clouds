terraform {
  required_version = ">= 0.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = local.region
}

# define a new virtual private network
resource "aws_vpc" "vnet" {
     cidr_block = "10.0.0.0/16"

     tags = {
     name        = "${local.application}-${local.environment}-vnet"
     application = local.application
     environment = local.environment
     team        = local.team
     }
}

# define a new subnet within virtual private network
resource "aws_subnet" "snet" {
     vpc_id                  = aws_vpc.vnet.id
     cidr_block              = "10.0.1.0/24"
     map_public_ip_on_launch = true
     availability_zone       = "${local.region}a"

     tags = {
     name        = "${local.application}-${local.environment}-snet"
     application = local.application
     environment = local.environment
     team        = local.team
     }
}

# generate an internet gateaway
resource "aws_internet_gateway" "igw" {
     vpc_id = aws_vpc.vnet.id

     tags = {
     name        = "${local.application}-${local.environment}-igw"
     application = local.application
     environment = local.environment
     team        = local.team
     }
}

# define routing table
resource "aws_route_table" "rt" {
     vpc_id = aws_vpc.vnet.id

     route {
     cidr_block = "0.0.0.0/0"
     gateway_id = aws_internet_gateway.igw.id
     }

     tags = {
     name        = "${local.application}-${local.environment}-rt"
     application = local.application
     environment = local.environment
     team        = local.team
     }
}

resource "aws_route_table_association" "rta" {
     subnet_id      = aws_subnet.snet.id
     route_table_id = aws_route_table.rt.id
}

# create a security group
resource "aws_security_group" "asg" {
     # name   = "${local.application}-${local.environment}-sg"
     vpc_id = aws_vpc.vnet.id

     ingress {
     from_port   = 22
     to_port     = 22
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
     }

     egress {
     from_port   = 0
     to_port     = 0
     protocol    = "-1"
     cidr_blocks = ["0.0.0.0/0"]
     }

     tags = {
     name        = "${local.application}-${local.environment}-sg"
     application = local.application
     environment = local.environment
     team        = local.team
     }
}

# generate virtual machine
resource "aws_instance" "vm" {
     ami                    = "ami-068c0051b15cdb816"
     instance_type          = "t3.small"
     subnet_id              = aws_subnet.snet.id
     vpc_security_group_ids = [aws_security_group.asg.id]

     user_data = <<-EOF
     #!/bin/bash
     echo 'ec2-user:Password123!' | chpasswd
     sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
     systemctl restart sshd
     EOF

     tags = {
     name        = "${local.application}-${local.environment}-ec2"
     application = local.application
     environment = local.environment
     team        = local.team
     }
}
