#!/bin/bash

# ======================================================
# 🧩 Terraform Backend Setup Script (S3 + DynamoDB)
# ======================================================

# --- Configuration ---
BUCKET_NAME="retail-store-terraform-state-uncle"
DYNAMODB_TABLE="retail-store-terraform-locks"
REGION="us-east-1"

# --- Create S3 bucket ---
echo "🚀 Creating S3 bucket: $BUCKET_NAME ..."
if [ "$REGION" = "us-east-1" ]; then
  aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region $REGION
else
  aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region $REGION \
    --create-bucket-configuration LocationConstraint=$REGION
fi

# --- Enable versioning ---
echo "🔄 Enabling versioning on bucket: $BUCKET_NAME ..."
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# --- Create DynamoDB table ---
echo "🧱 Creating DynamoDB table: $DYNAMODB_TABLE ..."
aws dynamodb create-table \
  --table-name $DYNAMODB_TABLE \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $REGION

# --- Output summary ---
echo ""
echo "✅ Terraform backend resources created successfully!"
echo "--------------------------------------------"
echo "S3 Bucket:       $BUCKET_NAME"
echo "DynamoDB Table:  $DYNAMODB_TABLE"
echo "Region:          $REGION"
echo "--------------------------------------------"
echo ""
echo "🪄 Now update your Terraform backend block as follows:"
echo ""
cat <<EOF
terraform {
  backend "s3" {
    bucket         = "$BUCKET_NAME"
    key            = "terraform.tfstate"
    region         = "$REGION"
    dynamodb_table = "$DYNAMODB_TABLE"
    encrypt        = true
  }
}
EOF
