output "configure_kubectl" {
  description = "Command to update kubeconfig for this cluster"
  value       = module.retail_app_eks.configure_kubectl
}

output "vpc_id" {
  description = "VPC ID for cleanup operations"
  value       = module.vpc.inner.vpc_id
}

output "s3_bucket_name" {
  description = "S3 bucket name for state storage"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}