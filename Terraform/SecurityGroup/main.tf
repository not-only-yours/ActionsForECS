resource "aws_security_group" "security_group" {
  name        = "${var.environment}-${var.name}-security-group"
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.name}-sg"
    Environment = var.environment,
    Terraform = true
  }
}

resource "aws_security_group_rule" "security-group-rule-inbound-cidr" {
  for_each = {for ingress_cidr_block in var.ingress_cidr_blocks: ingress_cidr_block.description => ingress_cidr_block
  if var.allow_all_connection == false && var.ingress_cidr_blocks != []}
  security_group_id = aws_security_group.security_group.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = each.value.cidr_blocks
}

resource "aws_security_group_rule" "security-group-rule-inbound-anywhere" {
  for_each = {for ingress_cidr_block in var.ingress_cidr_blocks: ingress_cidr_block.description => ingress_cidr_block
  if var.allow_all_connection == true && var.ingress_cidr_blocks != []}
  security_group_id = aws_security_group.security_group.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "security-group-rule-egress-cidr" {
  for_each = {for egress_cidr_block in var.egress_cidr_blocks: egress_cidr_block.description => egress_cidr_block
  if var.allow_all_outbound_traffic == false && var.egress_cidr_blocks != []}
  security_group_id = aws_security_group.security_group.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = each.value.cidr_blocks
}

resource "aws_security_group_rule" "security-group-rule-egress-anywhere" {
  for_each = {for egress_cidr_block in var.egress_cidr_blocks: egress_cidr_block.description => egress_cidr_block
  if var.allow_all_outbound_traffic == true && var.egress_cidr_blocks != []}
  security_group_id = aws_security_group.security_group.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = ["0.0.0.0/0"]
}



resource "aws_security_group_rule" "security-group-rule-inbound-from-other-sg" {
  for_each = {for inbound_security_group in var.inbound_security_groups: inbound_security_group.description => inbound_security_group
  if var.allow_all_connection == false && var.inbound_security_groups != []}
  security_group_id = aws_security_group.security_group.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  source_security_group_id   = each.value.security_group
}

resource "aws_security_group_rule" "security-group-rule-outbound-from-other-sg" {
  for_each = {for outbound_security_group in var.outbound_security_groups: outbound_security_group.description => outbound_security_group
  if var.allow_all_connection == false && var.outbound_security_groups != []}
  security_group_id = aws_security_group.security_group.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  source_security_group_id   = each.value.security_group
}



