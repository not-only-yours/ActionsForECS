resource "aws_security_group_rule" "frontend-alb-ingress-80" {
  security_group_id = module.frontend-alb.security_group_id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
  #ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "frontend-alb-ingress-443" {
   security_group_id = module.frontend-alb.security_group_id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
  #security_group_id = aws_security_group.frontend-alb-ingress-443.id
}

resource "aws_security_group_rule" "frontend-task-ingress-80" {
  security_group_id        = module.fargate-frontend.service_sg_id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 80
  to_port                  = 80
  source_security_group_id = module.frontend-alb.security_group_id
}

resource "aws_security_group_rule" "frontend-task-ingress-443" {
  security_group_id        = module.fargate-frontend.service_sg_id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
  source_security_group_id = module.frontend-alb.security_group_id
}
