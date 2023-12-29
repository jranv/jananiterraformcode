terraform {
  backend "s3" {
    bucket         = "firstproject2023s3bucketforterraformdemo"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform_state"
  }
}