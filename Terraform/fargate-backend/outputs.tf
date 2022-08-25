output "service_arn" {
  description = "The Amazon Resource Name (ARN) that identifies the ECS service."
  value       = aws_ecs_service.service_backend.id
}

output "target_group_arn" {
  description = "The ARN of the Target Group used by Load Balancer."
  value       = [for tg_arn in aws_lb_target_group.task_backend : tg_arn.arn]
}

output "target_group_name" {
  description = "The Name of the Target Group used by Load Balancer."
  value       = [for tg_name in aws_lb_target_group.task_backend : tg_name.name]
}

output "task_role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the ECS service role."
  value       = aws_iam_role.execution_backend.arn
}

output "task_role_name" {
  description = "The name of the Fargate task service role."
  value       = aws_iam_role.execution_backend.name
}

output "service_sg_id" {
  description = "The Amazon Resource Name (ARN) that identifies the service security group."
  value       = aws_security_group.ecs_service_backend.id
}

output "service_name" {
  description = "The name of the service."
  value       = aws_ecs_service.service_backend.name
}

output "log_group_name" {
  description = "The name of the Cloudwatch log group for the task."
  value       = aws_cloudwatch_log_group.main_backend.name
}

output "execution_role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the ECS execution role."
  value       = aws_iam_role.execution_backend.arn
}

output "execution_role_name" {
  description = "The name of the ECS execution role."
  value       = aws_iam_role.execution_backend.name
}

output "task_definition_arn" {
  description = "The Amazon Resource Name (ARN) of the task definition created"
  value       = aws_ecs_task_definition.task_backend.arn
}

output "task_definition_name" {
  description = "The name of the task definition created"
  value       = aws_ecs_task_definition.task_backend.arn
}