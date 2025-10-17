#################################################
# ALB 구성 + 타겟그룹(ASG)
#################################################
# 1. Launch Template 설절
#   SG 
#   LT
# 2. ASG 설정 - ASG를 타겟그룹으로 설정할거라서
# 3. 타겟그룹(TG) 설정
#   SG
#   TG
# 4. ALB 설정
#   alb
#   alb lisnter
#   alb rule
#################################################

####################################
# 1. Launch Template 설정
#   SG 
#   LT
####################################
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
##############################
# default vpC 가져오기
data "aws_vpc" "default" {
  default = true
}
####################################
resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow http inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "allow_web"
  }
}
resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = var.server_http_port
  to_port           = var.server_http_port
}
resource "aws_vpc_security_group_ingress_rule" "allow_https_ipv4" {
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = var.server_https_port
  to_port           = var.server_https_port
}
# 필요시 22번 도 열어서 접속 시도, 단 이떄 키페어까지 입력하기
######
#outbound 규칙
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#####################################
# 1.Launch Template 구성
#   ami 설정
#####################################

#   ami 설정
#   Amazon Linux 2023 AMI
data "aws_ami" "amz2023ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.9.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Canonical
}

#   Launch Template 구성
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template
resource "aws_launch_template" "myLT" {
  name = "myLT"

  image_id = data.aws_ami.amz2023ami.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.allow_web.id]
  # https://developer.hashicorp.com/terraform/language/functions/filebase64
  user_data = filebase64("./LT_user_data.sh")

  lifecycle {
    create_before_destroy = true
  }
}

######################################
# 2. ASG 설정
#   서브넷 설정
#   ASG 설정
#######################################

#   서브넷 설정
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets
# default vpc의 모든 서브넷
data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
#   ASG 설정
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group
resource "aws_autoscaling_group" "myASG" {
  vpc_zone_identifier = data.aws_subnets.default_subnets.ids
  desired_capacity   = 2
  min_size           = var.instance_min_size
  max_size           = var.instance_max_size

  # 중요
  target_group_arns = [aws_lb_target_group.myTG.arn]
  depends_on = [aws_lb_target_group.myTG]

  launch_template {
    id      = aws_launch_template.myLT.id
  }
}

#################################
# 3. 타겟그룹(TG) 설정
#   SG
#   TG
#################################

# TG
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
# ALB Target Group
resource "aws_lb_target_group" "myTG" {
  name        = "My-ALB-Target-Group"
  #target_type = "alb"
  target_type = "instance"
  port        = var.server_http_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

##################################
# 4. ALB 설정
#   alb
#   alb lisnter
#   alb rule
##################################

#   alb
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
resource "aws_lb" "myALB" {
  name               = "myALB"
  # false 는 공인ip만 받기
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_web.id]
  subnets            = data.aws_subnets.default_subnets.ids

  # enable_deletion_protection = true
}

#   alb lisnter
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener
resource "aws_lb_listener" "myALB_listner" {
  load_balancer_arn = aws_lb.myALB.arn
  port              = var.server_http_port
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = "404"
    }
  }
}

#   alb rule
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule
resource "aws_lb_listener_rule" "static" {
  listener_arn = aws_lb_listener.myALB_listner.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myTG.arn
  }

}


