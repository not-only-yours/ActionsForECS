resource "aws_lb" "backend" {
  name               = "test-lb-tf"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.backend_lb.id]
  subnets            = module.vpc.private_subnets


  tags = {
    Environment = "production"
  }
}



#module "backend-alb" {
#  source  = "umotif-public/alb/aws"
#  version = "~> 2.0"
#
#  name_prefix        = "alb-backend"
#  load_balancer_type = "application"
#  internal           = false
#  vpc_id             = module.vpc.vpc_id
#  subnets            = module.vpc.private_subnets
#}
#
resource "aws_lb_listener" "backend-alb-3000" {
  load_balancer_arn = aws_lb.backend.arn
  port              = "3000"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = module.fargate-backend.target_group_arn[0]
  }
}