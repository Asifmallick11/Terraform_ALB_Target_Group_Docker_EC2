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