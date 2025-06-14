terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "terraform-state-bucket-inv"        # <= EXACTLY MATCH YOUR S3 BUCKET NAME
    key    = "deployment/terraform.tfstate" # <= Path within the bucket
    region = "us-east-1"                        # <= EXACTLY MATCH YOUR AWS_REGION SECRET
    #dynamodb_table = "terraform-lock-table"                      # <= EXACTLY MATCH YOUR DYNAMODB TABLE NAME
    encrypt = true
  }
}
