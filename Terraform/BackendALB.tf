resource "aws_lb" "backend" {
  name               = "alb-backend"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.backend_lb.id]
  subnets            = module.vpc.private_subnets


  tags = {
    Environment = var.ENV,
    Terraform = true
  }
}


resource "aws_lb_listener" "backend-alb" {
  load_balancer_arn = aws_lb.backend.arn
  port              = var.BACKEND_PORT
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = module.fargate-backend.target_group_arn[0]
  }
}