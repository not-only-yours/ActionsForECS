module "frontend-alb" {
  source  = "umotif-public/alb/aws"
  version = "~> 2.0"

  name_prefix        = "alb-frontend"
  load_balancer_type = "application"
  internal           = false
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_listener" "frontend-alb_80" {
  load_balancer_arn = module.frontend-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = module.fargate-frontend.target_group_arn[0]
  }
}