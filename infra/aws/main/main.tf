# main/main.tf
provider "aws" {
  region  = var.region
  profile = var.profile
}

# ========== VPC ==========
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "vpc-main"
  }
}

# ========== Subnets ==========
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = { Name = "public-subnet" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_b_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = { Name = "public-subnet-b" }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_a_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = { Name = "private-subnet-a" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_b_cidr
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = { Name = "private-subnet-b" }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# ========== Internet Gateway ==========
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "vpc-igw" }
}

# ========== Public Route Table ==========
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "public-rt" }
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ========== NAT Gateway (in public subnet) ==========
resource "aws_eip" "nat" {
  tags = { Name = "nat-eip" }
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags = { Name = "nat-gateway" }

  depends_on = [aws_internet_gateway.igw]
}

# ========== Private route tables (route to NAT) ==========
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "private-rt" }
}

resource "aws_route" "private_internet_access" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.natgw.id
}

resource "aws_route_table_association" "private_a_assoc" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b_assoc" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# ========== Security Groups ==========
# ALB security group: allow HTTP from anywhere
resource "aws_security_group" "alb_sg" {
  name        = "allow-http-alb"
  description = "Allow HTTP from internet to ALB"
  vpc_id      = aws_vpc.this.id

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "alb-sg" }
}

# EC2 security group: allow 80 from ALB only
resource "aws_security_group" "ec2_sg" {
  name        = "allow-from-alb"
  description = "Allow HTTP from ALB only"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "allow http from alb"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # allow outbound for package installs and other outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ec2-sg" }
}

# ========== ALB (Application Load Balancer) ==========
resource "aws_lb" "alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public.id, aws_subnet.public_b.id]
  security_groups    = [aws_security_group.alb_sg.id]
  tags = { Name = "app-alb" }
}

# Target group (instance targets)
resource "aws_lb_target_group" "tg" {
  name        = "app-targets"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "instance"
  health_check {
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# ========== EC2 Instance (private) ==========
# pick a recent Amazon Linux 2 AMI
data "aws_ami" "amazon_linux2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux2.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_a.id
  associate_public_ip_address = false
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = var.key_name != "" ? var.key_name : null
  tags = { Name = "app-private-instance" }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y nginx
              systemctl enable nginx
              echo "<h1>Hello from private EC2</h1>" > /usr/share/nginx/html/index.html
              systemctl start nginx
              EOF
}

# Attach EC2 to ALB target group
resource "aws_lb_target_group_attachment" "app_attachment" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.app.id
  port             = 80
}
 
# ========== S3 Buckets ==========
# App bucket (DVC or app data)
resource "aws_s3_bucket" "app_bucket" {
  bucket = var.app_bucket_name

  tags = {
    Name = "dvc-app-bucket"
  }
}
