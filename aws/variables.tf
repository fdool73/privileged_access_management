variable "region" {
  description = "AWS region"
  type        = string
}

variable "linux_ami_id" {
  description = "Amazon Linux AMI ID"
  type        = string
}

variable "windows_ami_id" {
  description = "Windows Server 2022 AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "cisco_cidr" {
  description = "The CIDR block for Cisco VPN"
  type        = string
}

variable "private_subnet_cidr" {
  description = "The CIDR block for the private subnets."
  type        = list(string)
}

variable "public_subnet_cidr" {
  description = "The CIDR block for the private subnets."
  type        = list(string)
}

variable "s3_bucket_name" {
  description = "S3 bucket for cloudtrail logs"
  type        = string
}

variable "cloudtrail_name" {
  description = "PAM cloudtrail logs"
  type        = string
}

variable "role_name" {
  description = "Temp PAM role name"
  type        = string
}