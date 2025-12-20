resource "aws_ecr_repository" "api_repo" {
  name                 = "tech-challenge-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "tech-challenge-api-repo"
  }
}
