output "vpc_private_subnets" {
  description = "VPC private subnets"
  value = module.vpc.private_subnets
}

output "vpc_public_subnets" {
  description = "VPC public subnets"
  value = module.vpc.public_subnets
}

output "vpc_default_security_group" {
  description = "VPC private subnets"
  value = module.vpc.default_security_group_id
}

output "vpc_id" {
  description = "VPC ID"
  value = module.vpc.vpc_id
}

output "ssm_messages_endpoint" {
  description = "VPC ID"
  value = aws_vpc_endpoint.ssm_messages_endpoint.id
}

output "ssm_endpoint" {
  description = "VPC ID"
  value = aws_vpc_endpoint.ssm_endpoint.id
}