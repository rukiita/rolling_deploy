# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "${var.project_name}-ECSTaskExecutionRole"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name 
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for CodeBuild
resource "aws_iam_role" "test-build-project-role" {
  name = "${var.project_name}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Sid = ""
      },
    ]
  })

  tags = {
    Name = "${var.project_name}-CodeBuildRole"
  }
}

# IAM Role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Sid = ""
      },
    ]
  })

  tags = {
    Name = "${var.project_name}-CodePipelineRole"
  }
}

# CodePipeline Policy
resource "aws_iam_policy" "codepipeline_policy" {
  name        = "${var.project_name}-codepipeline-policy"
  description = "IAM policy for CodePipeline"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetBucketLocation",
          "iam:PassRole",
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds",
          "codecommit:CancelPullRequest",
          "codecommit:CreatePullRequest",
          "codecommit:DescribePullRequest",
          "codecommit:GetPullRequest",
          "codecommit:GetPullRequestApprovalStates",
          "codecommit:GetPullRequestMergeOptions",
          "codecommit:MergePullRequestBySquash",
          "codecommit:PostCommentForPullRequest",
          "codecommit:UpdatePullRequestApprovalState",
          "codecommit:DescribeRepository",
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:GetUploadArchiveStatus",
          "codecommit:UploadArchive",
          "codecommit:CreateCommit",
          "codecommit:DescribeMergeConflicts",
          "codecommit:GetMergeOptions",
          "codestar-connections:UseConnection",
          "ecr:DescribeRepositories",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetAuthorizationToken"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# CodePipeline ロールにポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "codepipeline_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

# 統合されたカスタムポリシー (以前のポリシーを置き換えます)
resource "aws_iam_policy" "test-build-project-policy" {
  name        = "${var.project_name}-codebuild-policy"
  description = "IAM policy for CodeBuild to access ECR, CloudWatch Logs, Secrets Manager, and other resources"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        # ECR access
        {
          Effect = "Allow"
          Action = [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetRepositoryPolicy",
            "ecr:DescribeRepositories",
            "ecr:ListImages",
            "ecr:DescribeImages",
            "ecr:BatchGetImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:PutImage"
          ]
          Resource = "*" # ECRリポジトリからの読み込み、認証トークン取得
        },
        # Secrets Manager access (for Docker Hub credentials)
        {
          Effect = "Allow"
          Action = "secretsmanager:GetSecretValue"
          Resource = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.dockerhub_secret_name}*"
        },
      ],
      [
        # CloudWatch Logs へのアクセス
        {
          Effect = "Allow"
          Resource = [
            # 修正: aws_codebuild_project.test-build-project.name を使用
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${aws_codebuild_project.test-build-project.name}",
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${aws_codebuild_project.test-build-project.name}:*"
          ]
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
        },
        # S3 へのアクセス (変更なし)
        {
          Effect = "Allow"
          Resource = [
            "arn:aws:s3:::codepipeline-${data.aws_region.current.name}-*"
          ]
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketAcl",
            "s3:GetBucketLocation"
          ]
        },
        # CodeBuild レポートへのアクセス
        {
          Effect = "Allow"
          Action = [
            "codebuild:CreateReportGroup",
            "codebuild:CreateReport",
            "codebuild:UpdateReport",
            "codebuild:BatchPutTestCases",
            "codebuild:BatchPutCodeCoverages"
          ]
          Resource = [
            # 修正: aws_codebuild_project.test-build-project.name を使用
            "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:report-group/${aws_codebuild_project.test-build-project.name}-*"
          ]
        },
        # sts:GetCallerIdentity (変更なし)
        {
          Effect = "Allow"
          Action = "sts:GetCallerIdentity"
          Resource = "*"
        }
      ]
    )
  })
}