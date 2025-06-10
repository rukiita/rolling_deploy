# ECR リポジトリ
resource "aws_ecr_repository" "test-ecr" {
  name = var.ecr_repository_name

  tags = {
    Environment = var.environment
    Name        = "${var.project_name}-ecr-repository"
  }
}