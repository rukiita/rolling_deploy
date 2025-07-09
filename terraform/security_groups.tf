# ALB 用セキュリティグループ (インターネットからのHTTP/80アクセスを許可)
resource "aws_security_group" "alb_sg" {
  name_prefix = "${var.project_name}-alb-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  # HTTPSも許可する場合は追加
  # ingress {
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ALBSecurityGroup"
  }
}

# ECS Fargate タスク用セキュリティグループ (ALBからのHTTP/80アクセスのみ許可)
resource "aws_security_group" "fargate_sg" {
  name_prefix = "${var.project_name}-fargate-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # ALBのセキュリティグループからのアクセスのみ許可
    description     = "Allow HTTP from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # 外部への出力 (NAT Gateway経由)
  }

  tags = {
    Name = "${var.project_name}-FargateSecurityGroup"
  }
}
