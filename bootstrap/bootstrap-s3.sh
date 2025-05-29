#!/bin/bash
# Use this script to create a bucket for storing terraform state files

set -e

REGION="us-west-2"
BUCKET_NAME="ftw-api-terraform-state" # change to whatever is needed

# Create S3 bucket
aws s3api create-bucket \
  --region "${REGION}" \
  --bucket "${BUCKET_NAME}"

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

  echo "FTW's S3 backend bucket is ready!"