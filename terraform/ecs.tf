# ECS クラスター
resource "aws_ecs_cluster" "container-test-cluster" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled" # 必要に応じて"enabled"に
  }

  tags = {
    Name = "${var.project_name}-ECSCluster"
  }
}

# ECS タスク定義
resource "aws_ecs_task_definition" "container-test-task" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name        = "${var.project_name}-app"
      image       = "${aws_ecr_repository.test-ecr.repository_url}:latest"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80 # Fargateでは無視されるが、ALBターゲットグループの設定と合わせる
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project_name}-task"
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-ECSTaskDefinition"
  }
}

# ALB (Application Load Balancer)
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id # パブリックサブネットに配置

  tags = {
    Name = "${var.project_name}-ALB"
  }
}

# ALB ターゲットグループ
resource "aws_lb_target_group" "main" {
  name        = "${var.project_name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # FargateはIPモード

  health_check {
    path                = "/" # アプリケーションのヘルスチェックパスに合わせる
    protocol            = "HTTP"
    matcher             = "200-299"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-TargetGroup"
  }
}

# ALB リスナー (HTTP:80)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = {
    Name = "${var.project_name}-ALBListener"
  }
}

# ECS サービス (プライベートサブネットに配置)
resource "aws_ecs_service" "container-test-service" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.container-test-cluster.id
  task_definition = aws_ecs_task_definition.container-test-task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id # プライベートサブネットに配置
    security_groups  = [aws_security_group.fargate_sg.id] # Fargate用セキュリティグループを使用
    assign_public_ip = false # プライベートサブネットなのでパブリックIPは不要
  }

  # ロードバランサー設定
  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "${var.project_name}-app" # タスク定義のコンテナ名
    container_port   = 80
  }

  tags = {
    Name = "${var.project_name}-ECSService"
  }
}