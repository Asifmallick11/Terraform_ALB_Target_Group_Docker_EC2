provider "aws" {
  region = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

# Key Pair

resource "tls_private_key" "ec2-key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "ec2-key" {
  key_name   = "ec2_key"
  public_key = tls_private_key.ec2-key.public_key_openssh
}

# Vpc 

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_1" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-south-1a"
}

resource "aws_subnet" "public_2" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "ap-south-1b"
}

#Internet Gateway

resource "aws_internet_gateway" "gw" {

    vpc_id = aws_vpc.main.id

    tags = {
      Name = "main-ig"
    }
  
}

# Route Table

resource "aws_route_table" "public" {

    vpc_id = aws_vpc.main.id
    
    route = {
        cidr_block = "0.0.0.0/0" 
        gateway_id = aws_internet_gateway.gw.id
    }
  
}

#Route Table Association

resource "aws_route_table_association" "a" {
  subnet_id = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "b" {
  subnet_id = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Security Group

resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id 

   ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   }

   egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
   }
  
}

resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main.id

    ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
   }

  #   ingress {
  #   from_port = 3000
  #   to_port = 3000
  #   protocol = "tcp"
  #   security_groups = [aws_security_group.alb_sg.id]
  #  }

   ingress {
    from_port = 22
    to_port = 22 
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   }

   egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
   }
  }

# EC2 Instance

resource "aws_instance" "ec2-app" {

  count = 2 
  ami = var.ami_id 
  instance_type = var.instance_type
  subnet_id = element([aws_subnet.public_1.id , aws_subnet.public_2.id] , count.index)
  key_name = aws_key_pair.ec2-key.key_name
  security_groups = [aws_security_group.ec2_sg.id]

  user_data = <<-EOF
  #!/bin/bash
  yes | sudo apt update
  yes | sudo apt install apache2
  echo "<h1>Server Details</h1><p><strong>Hostname:</strong>$(hostname)</p><p><strong>IP Address:</strong>$(hostname -l | cut -d" "-f1)</p>" > /var/www/html/index.html
  sudo systemctl restart apache2
EOF

  tags = {
    Name = "${var.instance_name}-${count.index}"
  }

}

# Load Balancers with Target Group

resource "aws_lb" "applb" {

  name = "apache-alb"
  load_balancer_type = "application"
  subnets = [aws_subnet.public_1.id , aws_subnet.public_2.id]
  security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "alb_tg" {
  name     = "apache2-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2

  }
}

resource "aws_lb_target_group_attachment" "app-attachment" {
  count = 2
  target_group_arn = aws_lb_target_group.alb_tg.id
  target_id = aws_instance.app[count.index].id 
  port = 80
}

resource "aws_lb_listener" "app-listner" {

  load_balancer_arn = aws_lb.applb.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
  
}

output "alb_dns_name"{
  value = aws_lb.applb.dns_name
}