# プロジェクト名などの共通変数
variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "container-app"
}

# 環境変数
variable "environment" {
  description = "The deployment environment (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

# VPC の CIDR ブロック
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# パブリックサブネットの CIDR ブロック (複数のAZに対応)
variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets in different AZs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"] # AZごとに設定
}

# プライベートサブネットの CIDR ブロック (複数のAZに対応)
variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets in different AZs"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"] # AZごとに設定
}

# ECS タスクの CPU (Fargate)
variable "ecs_task_cpu" {
  description = "CPU units for ECS Fargate task"
  type        = number
  default     = 256
}

# ECS タスクのメモリ (Fargate)
variable "ecs_task_memory" {
  description = "Memory (in MB) for ECS Fargate task"
  type        = number
  default     = 512
}

# ECR リポジトリ名
variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "test-ecr"
}

# GitHub リポジトリの所有者とリポジトリ名
variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = "rukiita" # あなたのGitHubユーザー名
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "rolling_deploy" # あなたのGitHubリポジトリ名
}

# GitHub 接続 ARN
variable "codeconnections_connection_arn" {
  description = "ARN of the AWS CodeConnections connection to GitHub"
  type        = string
  default     = "arn:aws:codeconnections:ap-northeast-1:267375937715:connection/86a1b018-5eaf-48f0-944c-858c65d6e38c" # あなたのARNに置き換えてください
}

# CodePipeline のアーティファクトS3バケット名
variable "pipeline_artifact_s3_bucket_name" {
  description = "Name of the S3 bucket for CodePipeline artifacts"
  type        = string
  default     = "your-unique-pipeline-artifacts-bucket-name-12345" # 必ずユニークなバケット名に置き換えてください
}

# Docker Hub のシークレット名 (Secrets Manager)
variable "dockerhub_secret_name" {
  description = "Name of the Secrets Manager secret for Docker Hub credentials"
  type        = string
  default     = "dockerDev" # あなたのSecrets Managerシークレット名
}

variable "dockerhub_username" {
  description = "Docker Hub username for secrets manager"
  type        = string
  sensitive   = true # この変数が機密情報であることを示し、Terraformのログ出力などを抑制
}

variable "dockerhub_password" {
  description = "Docker Hub password for secrets manager"
  type        = string
  sensitive   = true # この変数が機密情報であることを示し、Terraformのログ出力などを抑制
}

# アベイラビリティゾーンのリスト
data "aws_availability_zones" "available" {
  state = "available"
}