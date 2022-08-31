#That resource create frontend alb and connect listener to it

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
  #target_group_arn = module.fargate-frontend.target_group_arn[0]

  default_action {
      type = "redirect"

      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"

      }
  }
}

resource "aws_lb_listener" "frontend-alb_443" {
  load_balancer_arn = module.frontend-alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.ARN_CERTIFICATE_FOR_HTTPS_CONNECTION_TO_FRONTEND_ALB

  default_action {
    type             = "forward"
    target_group_arn = module.fargate-frontend.target_group_arn[0]
  }
}
