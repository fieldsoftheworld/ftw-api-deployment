terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Matches the other modules; aws_iam_openid_connect_provider.thumbprint_list
      # is optional from 5.81 onward.
      version = "~> 5.81"
    }
  }
}
