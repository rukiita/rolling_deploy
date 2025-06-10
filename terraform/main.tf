# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# パブリックサブネット (複数AZ)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${data.aws_availability_zones.available.names[count.index]}"
  }
}

# プライベートサブネット (複数AZ)
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-private-subnet-${data.aws_availability_zones.available.names[count.index]}"
  }
}

# インターネットゲートウェイ
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-internet-gateway"
  }
}

# パブリックルートテーブル (複数AZのパブリックサブネットと関連付け)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.project_name}-public-route-table"
  }
}

# パブリックサブネットへのルートテーブルの関連付け
resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# NAT Gateway 用の Elastic IP (各AZに1つ)
resource "aws_eip" "nat_gateway_eip" {
  count = length(aws_subnet.public)
  vpc   = true

  tags = {
    Name = "${var.project_name}-nat-eip-${count.index}"
  }
}

# NAT Gateway (各パブリックサブネットに1つ)
resource "aws_nat_gateway" "nat_gateway" {
  count         = length(aws_subnet.public)
  allocation_id = aws_eip.nat_gateway_eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-nat-gateway-${count.index}"
  }

  # NAT GatewayがEIPに依存することを明示
  depends_on = [aws_internet_gateway.gw]
}

# プライベートルートテーブル (各AZのプライベートサブネット用)
resource "aws_route_table" "private_rt" {
  count  = length(aws_subnet.private)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    # 各プライベートサブネットに対応するAZのNAT Gatewayを使用
    nat_gateway_id = aws_nat_gateway.nat_gateway[count.index].id
  }

  tags = {
    Name = "${var.project_name}-private-route-table-${count.index}"
  }
}

# プライベートサブネットへのルートテーブルの関連付け
resource "aws_route_table_association" "private_assoc" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}