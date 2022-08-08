module "backend-alb" {
  source  = "umotif-public/alb/aws"
  version = "~> 2.0"

  name_prefix        = "alb-backend"
  load_balancer_type = "application"
  internal           = false
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.private_subnets
}

resource "aws_lb_listener" "backend-alb-80" {
  load_balancer_arn = module.backend-alb.arn
  port              = "3000"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = module.fargate-backend.target_group_arn[0]
  }
}