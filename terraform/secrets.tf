# secrets.tf

resource "aws_secretsmanager_secret" "docker_credentials" {
  name        = var.dockerhub_secret_name
  description = "Docker Hub credentials for CodeBuild"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.project_name}-DockerHubCredentials"
  }
}

resource "aws_secretsmanager_secret_version" "docker_credentials_version" {
  secret_id = aws_secretsmanager_secret.docker_credentials.id
  # ここで変数から値を受け取る
  secret_string = jsonencode({
    username = var.dockerhub_username # 変数として定義
    password = var.dockerhub_password # 変数として定義
  })
}