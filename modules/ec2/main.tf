terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}


# Data source for Deep Learning Base OSS Nvidia Driver GPU AMI (Ubuntu 24.04)
# This will always fetch the latest version automatically
data "aws_ami" "deep_learning_gpu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Deep Learning Base OSS Nvidia Driver GPU AMI (Ubuntu 24.04) *"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Create "Launch Template" for Auto Scaling Group
resource "aws_launch_template" "fastapi_app" {
  name_prefix   = "${var.environment}-fastapi-lt-"
  image_id      = data.aws_ami.deep_learning_gpu.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name != "" ? var.key_pair_name : null

  vpc_security_group_ids = var.security_group_ids

  iam_instance_profile {
    name = var.instance_profile_name
  }

  # Enable detailed monitoring
  monitoring {
    enabled = true
  }

  # EBS block device configuration
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = 60
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  # Enable instance metadata service
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  # Simplified user data script with integrated hardening
  user_data = base64encode(templatefile("${path.module}/scripts/user-data.sh", {
    ENVIRONMENT      = var.environment
    FASTAPI_APP_PORT = var.fastapi_app_port
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-fastapi-launch-template"
      Environment = var.environment
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create Auto Scaling Group
resource "aws_autoscaling_group" "fastapi_app" {
  name                      = "${var.environment}-fastapi-asg"
  vpc_zone_identifier       = var.private_subnet_ids
  target_group_arns         = [var.target_group_arn]
  health_check_type         = var.asg_config.health_check_type
  health_check_grace_period = var.asg_config.health_check_grace_period

  min_size         = var.asg_config.min_size
  max_size         = var.asg_config.max_size
  desired_capacity = var.asg_config.desired_capacity

  # Use latest version of launch template
  launch_template {
    id      = aws_launch_template.fastapi_app.id
    version = "$Latest"
  }

  # Instance refresh configuration
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-fastapi-app"
    propagate_at_launch = false
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Purpose"
    value               = "fastapi-app"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# EMBEDDINGS MODEL EC2 INSTANCE
################################################################################

# Data source for Ubuntu LTS AMI
data "aws_ami" "ubuntu_lts" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Generate SSH key pair if not provided
resource "tls_private_key" "embeddings_key" {
  count     = var.enable_embeddings_instance && var.embeddings_public_key == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create SSH Key Pair for embeddings instance
resource "aws_key_pair" "embeddings_key" {
  count      = var.enable_embeddings_instance ? 1 : 0
  key_name   = "${var.environment}-embeddings-key"
  public_key = var.embeddings_public_key != "" ? var.embeddings_public_key : tls_private_key.embeddings_key[0].public_key_openssh

  tags = {
    Name        = "${var.environment}-embeddings-key"
    Environment = var.environment
    Purpose     = "embeddings-instance-ssh"
  }
}

# Elastic IP for embeddings instance
resource "aws_eip" "embeddings_eip" {
  count  = var.enable_embeddings_instance ? 1 : 0
  domain = "vpc"

  tags = {
    Name        = "${var.environment}-embeddings-eip"
    Environment = var.environment
    Purpose     = "embeddings-instance"
  }
}

# Embeddings EC2 Instance
resource "aws_instance" "embeddings" {
  count                  = var.enable_embeddings_instance ? 1 : 0
  ami                    = data.aws_ami.ubuntu_lts.id
  instance_type          = var.embeddings_instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = var.embeddings_security_group_ids
  key_name               = aws_key_pair.embeddings_key[0].key_name
  iam_instance_profile   = var.instance_profile_name

  # Enable auto-assign public IP
  associate_public_ip_address = true

  # Root block device
  root_block_device {
    volume_size           = var.embeddings_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  # Enable detailed monitoring
  monitoring = true

  # Enable instance metadata service v2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tags = {
    Name        = "${var.environment}-embeddings-server"
    Purpose     = "embeddings-model"
    Owner       = "ml-team"
    Environment = var.environment
    CostCenter  = "ml-infrastructure"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

# Associate Elastic IP with embeddings instance
resource "aws_eip_association" "embeddings_eip_assoc" {
  count         = var.enable_embeddings_instance ? 1 : 0
  instance_id   = aws_instance.embeddings[0].id
  allocation_id = aws_eip.embeddings_eip[0].id
}