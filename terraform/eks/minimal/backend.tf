# Terraform Backend Configuration for CI/CD
# Uncomment after running terraform apply to create backend resources
# terraform {
#   backend "s3" {
#     bucket         = "retail-store-terraform-state"
#     key            = "eks/minimal/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "retail-store-terraform-locks"
#   }
# }