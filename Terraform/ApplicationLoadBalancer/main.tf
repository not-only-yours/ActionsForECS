resource "aws_lb" "alb" {

  name       = "${var.environment}-${var.name}"
  internal           = var.is_internal
  load_balancer_type = "application"

  security_groups = [aws_security_group.security_group_lb.id]
  subnets            = var.subnets
}

resource "aws_lb_listener" "alb_80" {
  count = var.is_internal ? 0 : 1
  load_balancer_arn = aws_lb.alb.arn
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


resource "aws_lb_listener" "backend-alb" {
  count = var.is_internal ? 1 : 0
  load_balancer_arn = aws_lb.alb.arn
  port              = var.internal_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = var.target_group_arn
  }
}

resource "aws_lb_listener" "alb_443" {
  count = var.certificate_arn == "" ? 0 : 1
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = var.target_group_arn
  }
}


resource "aws_security_group" "security_group_lb" {
  name        = "${var.environment}-${var.name}-security-group"
  vpc_id      = var.vpc_id

  ingress {
    from_port        = var.is_internal  ? var.internal_port                    : "443"
    to_port          = var.is_internal  ? var.internal_port                    : "443"
    protocol         = "tcp"
    security_groups  = var.is_internal  ? var.security_groups_ingress_traffic  : []
    cidr_blocks       = var.is_internal ? []                                   : ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
#   ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.name}-sg"
    Environment = var.environment,
    Terraform = true
  }
}


resource "aws_security_group_rule" "frontend-alb-ingress-443" {
  count = var.is_internal ? 0 : 1
  security_group_id = aws_security_group.security_group_lb.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}