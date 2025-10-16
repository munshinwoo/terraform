
#teeraform 설정
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.16.0"
    }
  }
}

# 프로바이더 설정
provider "aws" {
  region = "us-east-2"
}

# 데이터 소스
# amazon Linux 2023 AMI
data "aws_ami" "linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*.20251014.0-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Canonical
}

# ec2 생성
resource "aws_instance" "myInstance" {
  ami           = data.aws_ami.linux.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  key_name = "MyKeyPair"

  tags = {
    Name = "myInstance"
  }
}

# 보안 그룹 생성
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic and all outbound traffic"
  # VPC를 안주면 기본 VPC로 간다
  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
