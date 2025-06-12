terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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

  # Enable instance metadata service
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  # User data script for Ubuntu (Deep Learning AMI)
  user_data = base64encode(<<-EOF
        #!/bin/bash
        apt-get update
        apt-get upgrade -y
        
        # Ensure SSM agent is running (pre-installed on Deep Learning AMI)
        systemctl enable amazon-ssm-agent
        systemctl start amazon-ssm-agent
        
        # TODO: Figure out a better solution for deploying FTW app
    EOF
  )

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