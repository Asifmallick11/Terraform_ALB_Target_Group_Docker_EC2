provider "aws" {
  region = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

# Key Pair

resource "tls_private_key" "ec2-key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "ec2-key" {
  key_name   = "ec2_key"
  public_key = tls_private_key.ec2-key.public_key_openssh
}

# Vpc 

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_1" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-south-1a"
}

resource "aws_subnet" "public_2" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "ap-south-1b"
}

#Internet Gateway

resource "aws_internet_gateway" "gw" {

    vpc_id = aws_vpc.main.id

    tags = {
      Name = "main-ig"
    }
  
}

# Route Table

resource "aws_route_table" "public" {

    vpc_id = aws_vpc.main.id
    
    route = {
        cidr_block = "0.0.0.0/0" 
        gateway_id = aws_internet_gateway.gw.id
    }
  
}

