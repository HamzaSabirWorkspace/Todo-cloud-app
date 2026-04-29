provider "aws" {
  region = "us-east-1"
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name used for SSH access."
  type        = string
}

variable "ssh_cidr" {
  description = "CIDR block allowed to connect over SSH."
  type        = string
  default     = "0.0.0.0/0"
}

variable "allowed_app_cidr" {
  description = "CIDR block allowed to reach the Kubernetes NodePort service."
  type        = string
  default     = "0.0.0.0/0"
}

# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "todo-vpc"
  }
}

# Subnet
resource "aws_subnet" "main_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "todo-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "todo-igw"
  }
}

# Route Table
resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
}

# Route Table Association
resource "aws_route_table_association" "main_rta" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_rt.id
}

# Security Group
resource "aws_security_group" "todo_sg" {
  name        = "todo-sg"
  description = "Allow SSH and Kubernetes NodePort access"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  ingress {
    from_port   = 30000
    to_port     = 30000
    protocol    = "tcp"
    cidr_blocks = [var.allowed_app_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "todo_server" {
  ami           = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS in us-east-1
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.main_subnet.id
  vpc_security_group_ids = [aws_security_group.todo_sg.id]
  key_name      = var.key_name

  tags = {
    Name = "todo-instance"
  }
}

output "public_ip" {
  value = aws_instance.todo_server.public_ip
}

output "application_url" {
  value = "http://${aws_instance.todo_server.public_ip}:30000"
}
