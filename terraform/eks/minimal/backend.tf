terraform {
  backend "s3" {
    # These values will be provided during terraform init
    # bucket         = "retail-store-terraform-state-xxxxx"
    # key            = "terraform.tfstate"
    # region         = "eu-north-1"
    # dynamodb_table = "retail-store-terraform-locks"
    # encrypt        = true
  }
}