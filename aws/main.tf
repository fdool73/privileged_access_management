data "aws_availability_zones" "available" {}

# Create KMS key for encryption
resource "aws_kms_key" "encryption_key" {
  description             = "KMS Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# Create SSM instance profile
resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "SSMInstanceProfile"
  role = aws_iam_role.ssm_instance_role.name
}

# Create SSM instance role
resource "aws_iam_role" "ssm_instance_role" {
  name = "SSMInstanceRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach ssm core policy to instance role
resource "aws_iam_role_policy_attachment" "ssm_instance_core_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ssm_instance_role.name
}

# Attach cloudwatch agent policy to instance role
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.ssm_instance_role.name
}

# Create PAM role
resource "aws_iam_role" "session_manager_role" {
  name = var.role_name
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Create PAM role policy
resource "aws_iam_policy" "session_manager_policy" {
  name   = "SessionManagerPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action   = [
        "ssm:StartSession",
        "ssm:ResumeSession",
        "ssm:TerminateSession",
        "ssm:DescribeSessions",
        "ssm:DescribeInstanceInformation"
      ],
      Effect   = "Allow",
      Resource = "*"
    }]
  })
}

# Attach PAM policy to role
resource "aws_iam_role_policy_attachment" "session_manager_attachment" {
  policy_arn = aws_iam_policy.session_manager_policy.arn
  role       = aws_iam_role.session_manager_role.name
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.available.names
  private_subnets = var.private_subnet_cidr
  public_subnets  = var.public_subnet_cidr

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Terraform = "true"
    Environment = "sandbox"
    User = "fdooling"
  }
}

resource "aws_security_group" "ssm_session_manager" {
  name        = "ssm_session_manager"
  description = "Security group allowing inbound on port 443 from VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "ssm_endpoint" {
  vpc_id            = module.vpc.vpc_id
  vpc_endpoint_type = "Interface"
  service_name      = "com.amazonaws.${var.region}.ssm"
  security_group_ids = [aws_security_group.ssm_session_manager.id]
  subnet_ids = module.vpc.private_subnets
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssm_messages_endpoint" {
  vpc_id            = module.vpc.vpc_id
  vpc_endpoint_type = "Interface"
  service_name      = "com.amazonaws.${var.region}.ssmmessages"
  security_group_ids = [aws_security_group.ssm_session_manager.id]
  subnet_ids = module.vpc.private_subnets
  private_dns_enabled = true
}

module "session_manager" {
  source            = "./modules/session_manager"
  windows_ami_id = var.windows_ami_id
  linux_ami_id = var.linux_ami_id
  instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
  cloudtrail_name = var.cloudtrail_name
  s3_bucket_name = var.s3_bucket_name
  region = var.region
  instance_type = var.instance_type
  private_subnets = module.vpc.private_subnets
  security_group_id = aws_security_group.ssm_session_manager.id
}