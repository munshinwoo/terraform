##################
#작업순서
# vpc 생성 
# 게이트웨이 생성허고 vpc에 연결
# 퍼블릭 서브넷 연결
# 라우팅 테이블 생성 및 퍼블릭 서브넷에 연결
####################################

provider "aws"{
  region = "us-east-2"
}

# vpc 생성 
resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support = true

  # 정의 단계의 이름 "myvpc"랑 테그의 이름 같게 하기
  tags = {
    Name = "myvpc"
  }

}

# 게이트웨이 생성허고 vpc에 연결
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "myIGW"
  }
}

# 퍼블릭 서브넷 연결
resource "aws_subnet" "myPubSN" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "myPubSN"
  }
}

# 라우팅 테이블 생성 
resource "aws_route_table" "myRT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }

  tags = {
    Name = "myRT"
  }
}

# 퍼블릭 서브넷에 연결
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.myPubSN.id
  route_table_id = aws_route_table.myRT.id
}

resource "aws_instance" "myweb"{
  ami = "ami-077b630ef539aa0b5"
  instance_type = "t3.micro"

  user_data_replace_on_change = true
  subnet_id = aws_subnet.myPubSN.id

  vpc_security_group_ids = [aws_security_group.allow_8080.id]

  user_data = <<-EOF
#!/bin/bash
dnf -y install httpd mod_ssl
echo "MyWEB" > /var/www/html/index.html
systemctl enable --now httpd 
EOF

  tags = {
    Name = "myweb"
  }

}

resource "aws_security_group" "allow_8080" {
  name        = "allow_8080"
  description = "Allow 8080 inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  tags = {
    Name = "allow_8080"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.allow_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = "80"
  ip_protocol       = "tcp"
  to_port           = 80
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}