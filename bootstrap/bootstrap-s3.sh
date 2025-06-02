#!/bin/bash
# Use this script to create a bucket for storing terraform state files

set -e

REGION="us-west-2"
BUCKET_BASE_NAME="ftw-api-terraform-state"

# Generate a random 8-character hex suffix (similar to Terraform's random_id)
RANDOM_SUFFIX=$(openssl rand -hex 4)
BUCKET_NAME="${BUCKET_BASE_NAME}-${RANDOM_SUFFIX}"

# Check if AWS SSO profile argument is provided
PROFILE_ARG=""
if [ ! -z "$1" ]; then
  PROFILE_ARG="--profile $1"
  echo "Using AWS profile: $1"
else
  echo "Using default AWS credentials"
fi

# Create S3 bucket
echo "Creating S3 bucket: ${BUCKET_NAME}"
aws s3api create-bucket \
  --region "${REGION}" \
  --bucket "${BUCKET_NAME}" \
  --create-bucket-configuration LocationConstraint="${REGION}" \
  ${PROFILE_ARG}

# Enable versioning
echo "Enabling versioning on bucket..."
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled \
  ${PROFILE_ARG}

# Enable encryption
echo "Enabling encryption on bucket..."
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }' \
  ${PROFILE_ARG}

echo "FTW's S3 backend bucket is ready!"
echo "Bucket: ${BUCKET_NAME}"
echo "Region: ${REGION}"
echo ""
echo "IMPORTANT: Update the Terraform backend configuration!"
echo "In environments/*/main.tf, update the backend bucket name to:"
echo "  bucket = \"${BUCKET_NAME}\""