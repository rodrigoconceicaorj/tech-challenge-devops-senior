terraform {
  backend "s3" {
    bucket         = "tech-challenge-terraform-state-408093795144"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tech-challenge-terraform-locks"
    encrypt        = true
  }
}
