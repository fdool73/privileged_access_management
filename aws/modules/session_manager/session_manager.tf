# Create Linux EC2 instance with IMDSv2
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-metadata-transition-to-version-2.html
resource "aws_instance" "linux_session_manager_instance" {
  ami                    = var.linux_ami_id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnets[0]
  iam_instance_profile   = var.instance_profile
  vpc_security_group_ids = [var.security_group_id]
  monitoring = true

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "session-manager-linux-instance"
  }
}

# Create Windows Server 2022 instance with IMDSv2
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-metadata-transition-to-version-2.html
resource "aws_instance" "windows_session_manager_instance" {
  ami                    = var.windows_ami_id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnets[0]
  iam_instance_profile   = var.instance_profile
  vpc_security_group_ids = [var.security_group_id]
  monitoring = true

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "session-manager-windows-instance"
  }
}


# CloudWatch Logs
resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name              = "/aws/cloudtrail/pam-cloudtrail-logs"
  retention_in_days = 7
}

# IAM Role for CloudTrail
resource "aws_iam_role" "cloudtrail_role" {
  name = "cloudtrail-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      }
    }
  ]
}
EOF
}

# IAM Policy for CloudTrail to Write to CloudWatch Logs
resource "aws_iam_policy" "cloudtrail_logs_policy" {
  name        = "cloudtrail-logs-policy"
  description = "Policy for CloudTrail to write to CloudWatch Logs"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
    }
  ]
}
EOF
}

# Attach the IAM policy to the CloudTrail role
resource "aws_iam_role_policy_attachment" "cloudtrail_logs_attachment" {
  policy_arn = aws_iam_policy.cloudtrail_logs_policy.arn
  role       = aws_iam_role.cloudtrail_role.name
}

# CloudTrail
resource "aws_cloudtrail" "cloudtrail" {
  depends_on = [aws_s3_bucket.cloudtrail_bucket]
  name                  = var.cloudtrail_name
  s3_bucket_name        = var.s3_bucket_name
  include_global_service_events = true
  is_multi_region_trail = true
  enable_logging        = true
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
  cloud_watch_logs_role_arn = aws_iam_role.cloudtrail_role.arn
}


# KMS key for S3 encryption
resource "aws_kms_key" "s3key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 7
}

# Allow Cloudtrail S3 bucket permission
resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.bucket

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::pam-cloudtrail-logs"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::pam-cloudtrail-logs/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    }
  ]
}
EOF
}

# S3 Bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket = var.s3_bucket_name
}

# S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_bucket" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# S3 public access block
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
