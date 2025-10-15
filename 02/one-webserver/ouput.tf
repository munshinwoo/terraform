#################################
# outout 변수
######################
output "my_web_public_ip" {
  description = "My web server public ip"
  value       = aws_instance.example.public_ip
}

output "my_web_public_dns" {
  description = "My web server public dns"
  value = aws_instance.example.public_dns
}