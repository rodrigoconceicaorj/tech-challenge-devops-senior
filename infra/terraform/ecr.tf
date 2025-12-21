resource "aws_ecr_repository" "api_repo" {
  name                 = "tech-challenge-api"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  encryption_configuration {
    encryption_type = "KMS"
  }

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "tech-challenge-api-repo"
  }
}
