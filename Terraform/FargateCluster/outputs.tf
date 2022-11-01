output "sg_id" {
  value = module.fargate-security-group.id
}

output "target_group_arn" {
  description = "The ARN of the Target Group used by Load Balancer."
  value       = [for tg_arn in aws_lb_target_group.task : tg_arn.arn]
}

output "id" {
  value = aws_ecs_service.service.id
}