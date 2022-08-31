# Security Group Config that allow connection to the backend alb from fargate frontend cluster

resource "aws_security_group" "backend_lb" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "TLS from VPC"
    from_port        = var.BACKEND_PORT
    to_port          = var.BACKEND_PORT
    protocol         = "tcp"
    security_groups      = [module.fargate-frontend.service_sg_id]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "alb-backend-sg"
    Environment = var.ENV,
    Terraform = true
    }
}