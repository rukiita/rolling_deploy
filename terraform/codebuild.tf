# CodeBuild プロジェクト
resource "aws_codebuild_project" "test-build-project" {
  name         = "${var.project_name}-build-project"
  service_role = aws_iam_role.test-build-project-role.arn
  build_timeout = 5 # タイムアウトは適切に設定

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "AWS_REGION"
      value = data.aws_region.current.name
    }
    environment_variable {
      name  = "ECR_REPOSITORY"
      value = aws_ecr_repository.test-ecr.repository_url
    }
  }

  source {
    type            = "CODEPIPELINE" # CodePipelineのソースとして使用
    # locationはCodePipeline側で設定されるため、ここでは指定しない
    # GitHubリポジトリのURLはCodePipelineのSourceステージで指定
    git_clone_depth = 1 # 履歴のクローン深度を制限し、ビルド時間を短縮
  }

  artifacts {
    type = "CODEPIPELINE" # CodePipelineのアーティファクトとして出力
  }

  cache {
    type = "NO_CACHE" # 必要に応じてS3キャッシュなどを設定
  }

  tags = {
    Name = "${var.project_name}-CodeBuildProject"
  }
}
