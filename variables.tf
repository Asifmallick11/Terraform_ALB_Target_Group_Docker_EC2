variable "aws_region" {
  description = "AWS region to deploy resources in"
  type = string
}

variable "access_key" {
    description = "Access Key"
    type = string
    sensitive = true
}

variable "secret_key" {
    description = "Secret Key"
    type = string
    sensitive = true
}

variable "ami_id" {
  description = "AMI-Id"
  type = string
}

variable "instance_type" {
  description = "Instance Type"
  type = string
}

variable "instance_name" {
  description = "Instance Name"
  type = string 
}

variable "public_key" {
  description = "Public Key"
  type = string
}

variable "private_key" {
  description = "Private Key"
  type = string
}