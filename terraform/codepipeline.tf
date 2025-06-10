# CodePipeline
resource "aws_codepipeline" "container-test-pipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = var.pipeline_artifact_s3_bucket_name
    type     = "S3"
    region   = data.aws_region.current.name
  }

  stage {
    name = "Source"
    action {
      name            = "GitHub"
      category        = "Source"
      owner           = "ThirdParty" # GitHubはThirdParty
      provider        = "GitHub"
      version         = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn = var.codeconnections_connection_arn # variables.tfで定義
        Owner         = var.github_owner                    # variables.tfで定義
        Repo          = var.github_repo                     # variables.tfで定義
        Branch        = "main"                              # デフォルトブランチに合わせてください
        # PollForSourceChanges = false # CodeConnectionsを使用する場合はポーリング不要
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "BuildImage"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      configuration = {
        ProjectName = aws_codebuild_project.test-build-project.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "DeployToECS"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]
      configuration = {
        ClusterName    = aws_ecs_cluster.container-test-cluster.name
        ServiceName    = aws_ecs_service.container-test-service.name
        TaskDefinition = aws_ecs_task_definition.container-test-task.arn
        ImageTag       = "latest" # CodeBuildがこのタグでイメージをプッシュすると想定
      }
    }
  }

  tags = {
    Name = "${var.project_name}-CodePipeline"
  }
}