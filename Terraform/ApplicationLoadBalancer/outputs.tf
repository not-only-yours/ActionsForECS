output "sg_id" {
  value = aws_security_group.security_group_lb.id
}

output "dns_name" {
  value = aws_lb.alb.dns_name
}

output "zone_id" {
  value = aws_lb.alb.zone_id
}