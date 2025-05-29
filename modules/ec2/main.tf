terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


# Use basic AL23 AMI as default
# For GPU instances, use a Deep Learning AMI
# Example: ami-0c02fb55956c7d316 (Deep Learning AMI with CUDA/Docker pre-installed)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64"]
  }

  filter {
    name   = "vitualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Create "Launch Template" for Auto Scaling Group
resource "aws_launch_template" "fastapi_app" {
  name_prefix   = "${var.environment}-fastapi-lt-"
  image_id      = data.aws_ami.amazon_linux.id
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

  # Enable instance metadata service
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  # Basic user data for system updates
  # TODO: Figure out a better solution for deploying FTW app
  user_data = base64encode(<<-EOF
        #!/bin/bash
        yum update -y
        # Install SSM agent (should be pre-installed on AL2023)
        yum install -y amazon-ssm-agent
        systemctl enable amazon-ssm-agent
        systemctl start amazon-ssm-agent
    EOF
  )

  tag_specifications {
    Name        = "${var.environment}-fastapi-launch-template"
    Environment = var.environment
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