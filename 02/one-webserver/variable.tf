variable "my_region" {
  description = "AWS My Region"
  type        = string
  default     = "us-east-2"
}

variable "my_ami_ubuntu2204" {
  description = "AWS My AMI Ubuntu 24.04 LTS(x86_64)"
  type        = string
  default     = "ami-0cfde0ea8edd312d4"
}

variable "my_instance_type" {
  description = "My ununtu instance type"
  type        = string
  default     = "t3.micro"
}

variable "my_userdata_changed" {
  description = "User data Replace change"
  type        = bool
  default     = true
}

variable "my_web_server_tag" {
  description = "My webserver tag"
  type        = map(string)
  default = {
    Name = "Mywebserver"
  }
}

variable "my_sg_tags" {
  description = "My security group tags"
  type = map(string)
  default = {
    Name = "allow_8080"
  }
}

variable "my_http_port" {
  description = "My web server port"
  type = number
  default = 8080
}