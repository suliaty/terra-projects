provider "aws" {
  
}


#Remote state with s3
terraform {
  backend "s3" {
    bucket = "my-statefile"
    key    = "terraform.tfstate"
    dynamodb_table = "my-Dynamo"
    region = "us-east-1"
  }
}

 #VPC block
 module "myvpc" {
   source = "./networking-module"
   vpc-cidr = "192.168.0.0/16"
   pub-cidr ="192.168.1.0/24"
   priv-cidr ="192.168.5.0/24"
  
}

#security group
resource "aws_security_group" "mysg" {
  name        = "allow_http"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.myvpc.vpc-id

ingress {
    description      = "HTTP from Anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH from Anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-http"
  }
}

#Instance with user-data scripts
resource "aws_instance" "newec2" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  #count = 2
  key_name = "sonarqube key"
  associate_public_ip_address = true
  user_data = <<-EOF
  #!/bin/bash
  sudo apt update
  sudo apt install apache2 -y
  sudo systemctl start apache2
  EOF
   vpc_security_group_ids = [aws_security_group.mysg.id]
   subnet_id = module.myvpc.pub-id
   tags = {
    Name = "newec2"
  }
}

#Load balancer and components
resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.mysg.id]
  subnets = [module.myvpc.pub-id,module.myvpc.priv-id]
  tags = {
    Name = "App-load-balancer"
  }
}

resource "aws_lb_target_group" "test" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.myvpc.vpc-id
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.newec2.id
  port             = 80
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.test.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }
}

#Output Loab balancer dns
output "lb_url" {
  value = aws_lb.test.dns_name
}