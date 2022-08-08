#####
# Security Group Config
#####
resource "aws_security_group_rule" "alb_ingress_80" {
  security_group_id = module.backend-alb.security_group_id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 3000
  to_port           = 3000
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "task_ingress_80" {
  security_group_id        = module.fargate-backend.service_sg_id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 3000
  to_port                  = 3000
  source_security_group_id = module.backend-alb.security_group_id
}