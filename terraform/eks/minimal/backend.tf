terraform {
  backend "s3" {
    bucket         = "retail-store-terraform-state-uncle"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "retail-store-terraform-locks"
    encrypt        = true
  }
}