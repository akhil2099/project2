provider "aws" {
  region = "ap-south-1" # Change this to your desired AWS region
}

# Define the server instance
resource "aws_instance" "server" {
  ami           = "ami-03f4878755434977f" # Change this to your desired server AMI ID
  instance_type = "t2.micro"              # Change this to your desired instance type
  key_name      = "akhil"                 # Replace "your_key_pair_name" with the name of your key pair
  tags = {
    Name = "server-akhil"
  }

  # Set metadata_options for IMDSv2
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  vpc_security_group_ids = ["sg-05e1a407803405527"] # Associate the specified security group
}

# Define the client instances
resource "aws_instance" "clients" {
  count         = 2
  ami           = "ami-03f4878755434977f" # Change this to your desired client AMI ID
  instance_type = "t2.micro"              # Change this to your desired instance type
  key_name      = "akhil"                 # Replace "your_key_pair_name" with the name of your key pair
  tags = {
    Name = "client-akhil-${count.index + 1}"
  }

  # Set metadata_options for IMDSv2
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  vpc_security_group_ids = ["sg-05e1a407803405527"] # Associate the specified security group
}

# Define an AWS Application Load Balancer (ALB)
resource "aws_lb" "alb" {
  name               = "akhilloadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-05e1a407803405527"]                                 # Replace this with your Security Group ID
  subnets            = ["subnet-06bf6e4a222be83c4", "subnet-0a2c4cbc33cad1ee2"] # Replace these with your subnet IDs
}

# Define a target group for the client instances
resource "aws_lb_target_group" "client_target_group" {
  name        = "client-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "vpc-0b6d5d0dbb0504425" # Replace this with your VPC ID
  target_type = "instance"
}

# Attach the client instances to the target group
resource "aws_lb_target_group_attachment" "client_attachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.client_target_group.arn
  target_id        = aws_instance.clients[count.index].id
}

# Listener rule for the ALB
resource "aws_lb_listener_rule" "client_listener_rule" {
  listener_arn = aws_lb.alb.arn # Replace aws_lb.alb.arn with the correct ARN of your ALB listener
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.client_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

