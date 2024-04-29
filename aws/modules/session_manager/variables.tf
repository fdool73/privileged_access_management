variable "region" {
  description = "AWS region"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket for cloudtrail logs"
  type        = string
}

variable "cloudtrail_name" {
  description = "PAM cloudtrail logs"
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

variable "instance_profile" {
  description = "PAM Admin instance profile ARN"
  type        = string
}

variable "api_secret" {
  description = "Dummy API key for Secrets Manager"
  type        = string
  default     = ""  
}

variable "db_secret" {
  description = "Dummy DB string for Secrets Manager"
  type        = string
  default     = ""
}

variable "kms_key" {
  description = "KMS key name"
  type        = string
  default     = "pam-poc-kms"
}

variable "private_subnets" {
  description = "List of private subnets in the VPC"
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "List of public subnets in the VPC"
  type        = list(string)
  default     = []
}

variable "security_group_id" {
  description = "ID of the security group for the session manager instances"
  type        = string
}

