provider "aws" {
  region = var.my_region
}

# ec2 instance 생성
#  
resource "aws_instance" "example" {
  ami           = var.my_ami_ubuntu2204
  instance_type = var.my_instance_type

  tags =  var.my_web_server_tag
  #echo "Hello, World" > index.html
  #nohup busybox httpd -f -p 8080 &

  user_data = <<-EOF
#!/bin/bash
echo "Hello, World" > index.html
nohup busybox httpd -f -p 8080 &
EOF

  user_data_replace_on_change = var.my_userdata_changed
  vpc_security_group_ids      = [aws_security_group.allow_8080.id]
}

resource "aws_security_group" "allow_8080" {
  name        = "allow_8080"
  description = "Allow 8080 inbound traffic and all outbound traffic"

  tags = var.my_sg_tags
}

resource "aws_vpc_security_group_ingress_rule" "allow_8080_ipv4" {
  security_group_id = aws_security_group.allow_8080.id
  # 모든 ip의 포트로 부터
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = var.my_http_port
  ip_protocol = "tcp"
  to_port     = var.my_http_port
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_8080.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


